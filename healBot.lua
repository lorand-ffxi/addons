_addon.name = 'healBot'
_addon.author = 'Lorand'
_addon.command = 'hb'
_addon.version = '1.5'

require('luau')
rarr = string.char(129,168)
res = require('resources')
require 'healBot_utils'
require 'healBot_buffing'
require 'healBot_curing'
require 'healBot_follow'

debugMode = true
active = false
actionDelay = 0.8
followTarget = nil
follow = false

enfeebling = T{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,155,156,157,158,159,167,168,174,175,177,186,189,192,193,194,223,259,260,261,262,263,264,298,378,379,380,386,387,388,389,390,391,392,393,394,395,396,397,398,399,400,404,448,449,450,451,452,473,540,557,558,559,560,561,562,563,564,565,566,567}
buffList = {}
debuffList = {}

windower.register_event('addon command', function (command,...)
    command = command and command:lower() or 'help'
    local args = {...}
	
	if command == 'reload' then
		windower.send_command('lua unload healBot; lua load healBot')
	elseif command == 'unload' then
		windower.send_command('lua unload healBot')
	elseif S{'start','on'}:contains(command) then
		activate()
	elseif S{'stop','end','off'}:contains(command) then
		active = false
		printStatus()
	elseif command == 'buff' then
		local targetName = args[1] and args[1] or ''
		local spellA = args[2] and args[2] or ''
		local spellB = args[3] and ' '..args[3] or ''
		local spellName = spellA..spellB
		
		local target = windower.ffxi.get_mob_by_name(targetName)
		if target == nil then
			windower.add_to_chat(0, 'Invalid buff target: '..targetName)
			return
		end
		
		local spell = res.spells:with('en', spellName)
		if spell == nil then
			windower.add_to_chat(0, 'Invalid spell name: '..spellName)
			return
		end
		if not canCast(spell) then
			windower.add_to_chat(0, 'Unable to cast spell: '..spellName)
			return
		end
		
		if buffList[target.name] == nil then
			buffList[target.name] = {}
		end
		buffList[target.name][spell.en] = {['spell']=spell, ['maintain']=true}
		windower.add_to_chat(0, 'Will maintain buff: '..spell.en..' '..rarr..' '..target.name)
	elseif command == 'follow' then
		local name = args[1]
		if S{'off', 'end', 'false'}:contains(name) then
			follow = false
		else
			if name == '<t>' then
				name = windower.ffxi.get_mob_by_target().name
			end
			followTarget = name
			follow = true
			windower.add_to_chat(0, 'Now following '..followTarget)
		end
	elseif command == 'status' then
		printStatus()
	elseif command == 'info' then
		printInfo()
	else
		windower.add_to_chat(0, 'Error: Unknown command')
	end
end)

function getMonitoredPlayers()
	local pt = windower.ffxi.get_party()
	local pty = {pt.p0, pt.p1, pt.p2, pt.p3, pt.p4, pt.p5}
	local party = {}
	for _,player in pairs(pty) do
		if player ~= nil then
			party[player.name] = player
		end
	end
	return party
end

function canCast(spell)
	local player = windower.ffxi.get_player()
	if (player == nil) or (spell == nil) then return false end
	local mainCanCast = (spell.levels[player.main_job_id] ~= nil) and (spell.levels[player.main_job_id] <= player.main_job_level)
	local subCanCast = (spell.levels[player.sub_job_id] ~= nil) and (spell.levels[player.sub_job_id] <= player.sub_job_level)
	local spellAvailable = windower.ffxi.get_spells()[spell.id]
	return spellAvailable and (mainCanCast or subCanCast)
end

function activate()
	local player = windower.ffxi.get_player()
	if player ~= nil then
		maxCureTier = determineHighestCureTier()
		active = (maxCureTier > 0)
	end
	printStatus()
end

windower.register_event('load', function()
	lastAction = os.clock()
end)

windower.register_event('prerender', function()
	local now = os.clock()
	if (now - lastAction) >= actionDelay then
		local player = windower.ffxi.get_player()
		if (player ~= nil) and S{0,1}:contains(player.status) then	--Assert player is idle or engaged	
			local moving = false
			actionDelay = 0.08
			
			if follow then
				if not needToMove(followTarget) then
					windower.ffxi.run(false)
				else
					moveTowards(followTarget)
					moving = true
				end
			end
			
			if active and (not moving) then
				if not cureSomeone(player) then
					checkBuffs(player, buffList)
				end
			end
		end	--player status check
		lastAction = now
	end	--time check
end)

function isTooFar(name)
	local target = windower.ffxi.get_mob_by_name(name)
	if target ~= nil then
		return target.distance > 432	--20.8 in game
	end
	return true
end

function printInfo()
	windower.add_to_chat(0, 'healBot comands: (to be implemented)')
end

function printStatus()
	windower.add_to_chat(0, 'healBot: '..(active and 'active' or 'off'))
end

windower.register_event('incoming chunk', function(id, data)
	if id == 0x028 then	--Action Packet
		local players = getMonitoredPlayers()
		local act = get_action_info(id, data)
		--local actor = windower.ffxi.get_mob_by_id(act.actor_id).name
		for _,target in pairs(act.targets) do
			local tname = windower.ffxi.get_mob_by_id(target.id).name
			if players[tname] then
				for _,tact in pairs(target.actions) do	--Iterate through the actions performed on the target
					--atcd('[0x028]Action('..tact.message..'): '..actor..'['..act.actor_id..'] { '..act.param..' } '..rarr..' '..tname..'['..target.id..']'..' { '..tact.param..' }')
					if S{2}:contains(tact.message) then	--Magic damage
						local spell = res.spells[act.param]	--act.param: spell; tact.param: damage
						if S{230,231,232,233,234}:contains(act.param) then
							registerDebuff(tname, 'Bio', true)
						elseif S{23,24,25,26,27,33,34,35,36,37}:contains(act.param) then
							registerDebuff(tname, 'Dia', true)
						end
					elseif S{230}:contains(tact.message) then	--Gain status effect
						local buff = res.buffs[tact.param]
						if enfeebling:contains(tact.param) then
							registerDebuff(tname, buff.en, true)
						else
							local spell = res.spells[act.param]
							registerBuff(tname, spell.en, true)
						end
					elseif S{341}:contains(tact.message) then	--Remove status ailment
						local buff = res.buffs[tact.param]
						if enfeebling:contains(tact.param) then
							registerDebuff(tname, buff.en, false)
						else
							registerBuff(tname, buff.en, false)
						end
					end
					--242, 277: venom shell; tact.param = 3 = poison
					--83: poisona; tact.param = 3 = poison
				end
			end
		end
	elseif id == 0x029 then	--Action Message
		local players = getMonitoredPlayers()
		local am = get_action_info(id, data)
		local buff = res.buffs[am.param_1]
		--local actor = windower.ffxi.get_mob_by_id(am.actor_id).name
		local tname = windower.ffxi.get_mob_by_id(am.target_id).name
		if players[tname] then
			--atcd('[0x029]Action Message('..am.message_id..'): '..actor..'['..am.actor_id..'] '..rarr..' '..tname..'['..am.target_id..']'..' { '..tostring(am.param_1)..' | '..tostring(am.param_2)..' | '..tostring(am.param_3)..' }')
			if S{204,206}:contains(am.message_id) then	--Status effect/ailment wears off
				if enfeebling:contains(am.param_1) then
					registerDebuff(tname, buff.en, false)
				else
					registerBuff(tname, buff.en, false)
				end
			end
		end
	end
end)

function registerDebuff(targetName, debuffName, gain)
	if debuffList[targetName] == nil then
		debuffList[targetName] = {}
	end
	if gain then
		debuffList[targetName][debuffName] = {['landed']=os.clock()}
		atcd("Debuff: "..debuffName.." "..rarr.." "..targetName)
	else
		debuffList[targetName][debuffName] = nil
		atcd("Debuff: "..debuffName.." wore off "..targetName)
	end
end

function registerBuff(targetName, buffName, gain)
	if buffList[targetName] == nil then
		buffList[targetName] = {}
	end
	--TODO: Handle other tiered spells, such as protect/shell, phalanx
	if S{'Haste', 'Refresh'}:contains(buffName) then
		if buffList[targetName][buffName] == nil then
			buffName = buffName..' II'
		end
	end
	if buffList[targetName][buffName] ~= nil then
		if gain then
			buffList[targetName][buffName]['landed'] = os.clock()
			atcd("Buff: "..buffName.." "..rarr.." "..targetName)
		else
			buffList[targetName][buffName]['landed'] = nil
			atcd("Buff: "..buffName.." wore off "..targetName)
		end
	end
end

function atcd(text)
	if debugMode then atc(text) end
end

-----------------------------------------------------------------------------------------------------------
--[[
Copyright © 2015, Lorand
All rights reserved.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of ffxiHealer nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Lorand BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]
-----------------------------------------------------------------------------------------------------------