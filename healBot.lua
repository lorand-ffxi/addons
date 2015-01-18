_addon.name = 'healBot'
_addon.author = 'Lorand'
_addon.command = 'hb'
_addon.version = '1.4'

require('luau')
rarr = string.char(129,168)
res = require('resources')
require 'healBot_buffing'
require 'healBot_curing'
require 'healBot_follow'

active = false
actionDelay = 0.8
followTarget = nil
follow = false

buffList = {}

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
		buffList[target.name][spell.en] = {['spell']=spell}
		--table.insert(buffList[target.name], {['buff']=spell.en, ['duration']=spell.duration, ['cast_time']=spell.cast_time})
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
				if not moving then
					if not cureSomeone(player) then
						checkBuffs(player, buffList)
					end
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