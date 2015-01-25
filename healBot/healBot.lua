_addon.name = 'healBot'
_addon.author = 'Lorand'
_addon.command = 'hb'
_addon.version = '2.1.3'

require('luau')
rarr = string.char(129,168)
res = require('resources')
config = require('config')
require 'healBot_utils'
require 'healBot_buffing'
require 'healBot_curing'
require 'healBot_follow'

aliases = config.load('..\\shortcuts\\data\\aliases.xml')

debugMode = false
active = false
actionDelay = 0.08
followTarget = nil
follow = false
followDist = 3
followDelay = 0.08
showPacketInfo = false

enfeebling = T{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,155,156,157,158,159,167,168,174,175,177,186,189,192,193,194,223,259,260,261,262,263,264,298,378,379,380,386,387,388,389,390,391,392,393,394,395,396,397,398,399,400,404,448,449,450,451,452,473,540,557,558,559,560,561,562,563,564,565,566,567}
trusts = S{'Joachim', 'Ulmia', 'Cherukiki', 'Tenzen'}
buffList = {}
debuffList = {}
ignoreList = S{}
extraWatchList = S{}

texts = require('texts')
moveInfo = texts.new({pos={x=0,y=0}})
showMoveInfo = false

defaultBuffs = {
	['self'] = {'Haste II', 'Refresh II', 'Aquaveil', 'Protect V', 'Shell V', 'Phalanx', 'Reraise'},
	['melee'] = {'Haste II', 'Phalanx II', 'Protect V', 'Shell V'},
	['mage'] = {'Haste II', 'Refresh II', 'Protect V', 'Shell V', 'Phalanx II'},
	['melee2'] = {'Haste II', 'Phalanx II'},
	['mage2'] = {'Haste II', 'Refresh II', 'Phalanx II'}
}

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
	elseif command == 'moveinfo' then
		if args[1] ~= nil then
			if S{'show', 'on'}:contains(args[1]:lower()) then
				showMoveInfo = true
			elseif S{'hide', 'off'}:contains(args[1]:lower()) then
				showMoveInfo = false
			end
		else
			atc('Error: No argument specified for moveInfo')
		end
	elseif command == 'reset' then
		local b = false
		local d = false
		if (args[1] == nil) then
			b = true
			d = true
		elseif (args[1]:lower() == 'buffs') then
			b = true
		elseif (args[1]:lower() == 'debuffs') then
			d = true
		else
			atc('Error: Invalid argument specified for reset: '..arg[1])
		end
		if (b) then
			for player,_ in pairs(buffList) do
				resetBuffTimers(player)
			end
		end
		if (d) then
			debuffList = {}
		end
		checkOwnBuffs()
	elseif command == 'buff' then
		registerNewBuff(args, true)
	elseif command == 'cancelbuff' then
		registerNewBuff(args, false)
	elseif command == 'bufflist' then
		if args[1] ~= nil then
			local blist = defaultBuffs[args[1]]
			if blist ~= nil then
				for _,buff in pairs(blist) do
					registerNewBuff({args[2], buff}, true)
				end
			else
				atc('Error: Invalid argument specified for BuffList: '..args[1])
			end
		else
			atc('Error: No argument specified for BuffList')
		end
	elseif command == 'follow' then
		if args[1] ~= nil then
			if S{'off', 'end', 'false'}:contains(args[1]:lower()) then
				follow = false
			elseif S{'distance', 'dist', 'd'}:contains(args[1]:lower()) then
				local dist = tonumber(args[2])
				if (dist ~= nil) and (0 < dist) and (dist < 45) then
					followDist = dist
					atc('Follow distance set to '..followDist)
				else
					atc('Error: Invalid argument specified for follow distance')
				end
			else
				local name = args[1]
				if name == '<t>' then
					name = windower.ffxi.get_mob_by_target().name
				end
				followTarget = formatName(name)
				follow = true
				atc('Now following '..followTarget)
			end
		else
			atc('Error: No argument specified for follow')
		end
	elseif command == 'packetinfo' then
		if args[1] ~= nil then
			if args[1]:lower() == 'on' then
				atc('Will now display packet info')
				showPacketInfo = true
			elseif args[1]:lower() == 'off' then
				atc('Will no longer display packet info')
				showPacketInfo = false
			else
				atc('Invalid argunment for packetInfo: '..args[1])
			end
		else
			atc('Error: No argument specified for packetInfo')
		end
	elseif S{'ignore', 'unignore', 'watch', 'unwatch'}:contains(command) then
		monitorCommand(command, args[1])
	elseif command == 'status' then
		printStatus()
	elseif command == 'info' then
		printInfo()
	else
		atc('Error: Unknown command')
	end
end)

function registerNewBuff(args, use)
	local me = windower.ffxi.get_player()
	local targetName = args[1] and args[1] or ''
	local spellA = args[2] and args[2] or ''
	local spellB = args[3] and ' '..args[3] or ''
	local spellName = formatSpellName(spellA..spellB)
	
	if spellName == nil then
		atc('Error: Unable to parse spell name')
		return
	end
	
	local target = windower.ffxi.get_mob_by_name(targetName)
	if target == nil then
		if (targetName == '<t>') then
			target = windower.ffxi.get_mob_by_target()
		end
		if target == nil then		
			atc('Invalid buff target: '..targetName)
			return
		end
	end
	
	local spell = res.spells:with('en', spellName)
	if spell == nil then
		atc('Invalid spell name: '..spellName)
		return
	end
	if not canCast(spell) then
		atc('Unable to cast spell: '..spellName)
		return
	end
	
	local targetType = 'None'
	if (target.in_alliance) then
		if (target.in_party) then
			if (me.name == target.name) then
				targetType = 'Self'
			else
				targetType = 'Party'
			end
		else
			targetType = 'Ally'
		end
	end
	local validTargets = S(spell.targets)
	if (not validTargets:contains(targetType)) then
		atc(target.name..' is an invalid target for '..spell.en..' (Type: '..targetType..')')
		return
	end
	
	local monitoring = getMonitoredPlayers()
	if (not monitoring[target.name]) then
		monitorCommand('watch', target.name)
	end
	
	if buffList[target.name] == nil then
		buffList[target.name] = {}
	end
	--Strip tier to match buff name
	local idx = spell.en:find(" ")
	local g = spell.en
	if idx ~= nil then
		g = g:sub(1, idx-1)
	end
	
	if (use) then
		buffList[target.name][g] = {['spell']=spell, ['maintain']=true}
		atc('Will maintain buff: '..spell.en..' '..rarr..' '..target.name)
		if (targetType == 'Self') then
			checkOwnBuff(g)
		end
	else
		buffList[target.name][g] = nil
		atc('Will no longer maintain buff: '..spell.en..' '..rarr..' '..target.name)
	end
end

function monitorCommand(cmd, pname)
	if (pname == nil) then
		atc('Error: No argument specified for '..cmd)
		return
	end
	local name = formatName(pname)
	if cmd == 'ignore' then
		if (not ignoreList:contains(name)) then
			ignoreList:add(name)
			atc('Will now ignore '..name)
			if extraWatchList:contains(name) then
				extraWatchList:remove(name)
			end
		else
			atc('Error: Already ignoring '..name)
		end
	elseif cmd == 'unignore' then
		if (ignoreList:contains(name)) then
			ignoreList:remove(name)
			atc('Will no longer ignore '..name)
		else
			atc('Error: Was not ignoring '..name)
		end
	elseif cmd == 'watch' then
		if (not extraWatchList:contains(name)) then
			extraWatchList:add(name)
			atc('Will now watch '..name)
			if ignoreList:contains(name) then
				ignoreList:remove(name)
			end
		else
			atc('Error: Already watching '..name)
		end
	elseif cmd == 'unwatch' then
		if (extraWatchList:contains(name)) then
			extraWatchList:remove(name)
			atc('Will no longer watch '..name)
		else
			atc('Error: Was not watching '..name)
		end
	end
end

function isMoving()
	if (getPosition() == nil) then
		moveInfo:hide()
		return true
	end
	lastPos = lastPos and lastPos or getPosition()
	posArrival = posArrival and posArrival or os.clock()
	local currentPos = getPosition()
	local now = os.clock()
	local moving = true
	local timeAtPos = math.floor((now - posArrival)*10)/10
	if (lastPos:equals(currentPos)) then
		moving = (timeAtPos < 0.5)
	else
		lastPos = currentPos
		posArrival = now
	end
	if math.floor(timeAtPos) == timeAtPos then
		timeAtPos = timeAtPos..'.0'
	end
	moveInfo:text('Time @ '..currentPos:toString()..': '..timeAtPos..'s')
	moveInfo:visible(showMoveInfo)
	return moving
end

function getMonitoredPlayers()
	local pt = windower.ffxi.get_party()
	local pty = {pt.p0,pt.p1,pt.p2,pt.p3,pt.p4,pt.p5}
	local me = pt.p0
	local targets = S{}
	for _,player in pairs(pty) do
		if (player ~= nil) and (not ignoreList:contains(player.name)) and (me.zone == player.zone) then
			if (not trusts:contains(player.name)) then
				targets[player.name] = player
			end
		end
	end
	
	local alliance = {pt.a10,pt.a11,pt.a12,pt.a13,pt.a14,pt.a15,pt.a20,pt.a21,pt.a22,pt.a23,pt.a24,pt.a25}
	for _,ally in pairs(alliance) do
		if (ally ~= nil) and (extraWatchList:contains(ally.name)) and (me.zone == ally.zone) then
			targets[ally.name] = ally
		end
	end
	
	for extraName,_ in pairs(extraWatchList) do
		local extraPlayer = windower.ffxi.get_mob_by_name(extraName)
		if (extraPlayer ~= nil) and (not targets:contains(extraPlayer.name)) then
			targets[extraPlayer.name] = extraPlayer
		end
	end
	return targets
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
	checkOwnBuffs()
end

windower.register_event('load', function()
	lastAction = os.clock()
	lastFollowCheck = os.clock()
end)

windower.register_event('prerender', function()
	local now = os.clock()
	local moving = isMoving()
	local player = windower.ffxi.get_player()
	if (player ~= nil) and S{0,1}:contains(player.status) then	--Assert player is idle or engaged
		if follow and ((now - lastFollowCheck) > followDelay) then
			if not needToMove(followTarget) then
				windower.ffxi.run(false)
			else
				moveTowards(followTarget)
				moving = true
			end
			lastFollowCheck = now
		end
		
		if active and (not moving) and ((now - lastAction) > actionDelay) then
			if not cureSomeone(player) then						--Curing is 1st priority
				if not checkDebuffs(player, debuffList) then	--Debuff removal is 2nd priority
					checkBuffs(player, buffList)				--Buffing is 3rd priority
				end
			end
			lastAction = now
		end
	end
end)

function isTooFar(name)
	local target = windower.ffxi.get_mob_by_name(name)
	if target ~= nil then
		return math.sqrt(target.distance) > 20.8
		--return target.distance > 432	--20.8 in game
	end
	return true
end

windower.register_event('incoming chunk', function(id, data)
	if id == 0x028 then	--Action Packet
		local players = getMonitoredPlayers()
		local act = get_action_info(id, data)
		local actor = windower.ffxi.get_mob_by_id(act.actor_id).name	--Only needed for showing packet info
		for _,target in pairs(act.targets) do
			local tname = windower.ffxi.get_mob_by_id(target.id).name
			if players[tname] then
				for _,tact in pairs(target.actions) do	--Iterate through the actions performed on the target
					if (showPacketInfo) then
						atc('[0x028]Action('..tact.message..'): '..actor..'['..act.actor_id..'] { '..act.param..' } '..rarr..' '..tname..'['..target.id..']'..' { '..tact.param..' }')
					end
					if S{2}:contains(tact.message) then
						--Magic damage
						local spell = res.spells[act.param]	--act.param: spell; tact.param: damage
						if S{230,231,232,233,234}:contains(act.param) then
							registerDebuff(tname, 'Bio', true)
						elseif S{23,24,25,26,27,33,34,35,36,37}:contains(act.param) then
							registerDebuff(tname, 'Dia', true)
						end
					elseif S{82,127,141,166,186,194,203,205,230,236,237,242,243,266,267,268,269,270,271,272,277,278,279,280,319,320,321,374,375,412,645}:contains(tact.message) then
						--Gain status effect
						local buff = res.buffs[tact.param]	--act.param: spell; tact.param: buff/debuff
						if enfeebling:contains(tact.param) then
							registerDebuff(tname, buff.en, true)
						else
							registerBuff(tname, buff.en, true)
						end
					elseif S{64,83,123,168,204,206,322,341,342,343,344,350,378,531,647}:contains(tact.message) then
						--Lose status effect
						local buff = res.buffs[tact.param]	--act.param: spell; tact.param: buff/debuff
						if enfeebling:contains(tact.param) then
							registerDebuff(tname, buff.en, false)
						else
							registerBuff(tname, buff.en, false)
						end
					elseif S{84}:contains(tact.message) then
						--${actor} is paralyzed.
						if players[actor] then
							registerDebuff(actor, 'paralysis', true)
						end
					elseif S{75}:contains(tact.message) then
						--No effect
						local spell = res.spells[act.param]
						local debuffs = removal_map[spell.en]
						if (debuffs ~= nil) then
							for _,debuff in pairs(debuffs) do
								registerDebuff(tname, debuff, false)
							end
						end
					end
				end
			end
		end
	elseif id == 0x029 then	--Action Message
		local players = getMonitoredPlayers()
		local am = get_action_info(id, data)
		local buff = res.buffs[am.param_1]
		local actor = windower.ffxi.get_mob_by_id(am.actor_id).name		--Only needed for showing packet info
		local tname = windower.ffxi.get_mob_by_id(am.target_id).name
		if players[tname] then
			if (showPacketInfo) then
				atc('[0x029]Action Message('..am.message_id..'): '..actor..'['..am.actor_id..'] '..rarr..' '..tname..'['..am.target_id..']'..' { '..tostring(am.param_1)..' | '..tostring(am.param_2)..' | '..tostring(am.param_3)..' }')
			end
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
		atcd("Detected debuff: "..debuffName.." "..rarr.." "..targetName)
		if (debuffName == 'slow') then
			registerBuff(targetName, 'Haste', false)
		end
	else
		debuffList[targetName][debuffName] = nil
		atcd("Detected debuff: "..debuffName.." wore off "..targetName)
	end
end

function registerBuff(targetName, buffName, gain)
	if buffList[targetName] == nil then
		buffList[targetName] = {}
	end
	if buffList[targetName][buffName] ~= nil then
		if gain then
			buffList[targetName][buffName]['landed'] = os.clock()
			atcd("Detected buff: "..buffName.." "..rarr.." "..targetName)
		else
			buffList[targetName][buffName]['landed'] = nil
			atcd("Detected buff: "..buffName.." wore off "..targetName)
		end
	end
end

function resetDebuffTimers(player)
	debuffList[player] = {}
end

function resetBuffTimers(player)
	if buffList[player] == nil then return end
	for buffName,_ in pairs(buffList[player]) do
		buffList[player][buffName]['landed'] = nil
	end
end

function printInfo()
	windower.add_to_chat(0, 'healBot comands: (to be implemented)')
end

function printStatus()
	windower.add_to_chat(0, 'healBot: '..(active and 'active' or 'off'))
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