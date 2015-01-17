_addon.name = 'healBot'
_addon.author = 'Lorand'
_addon.command = 'hb'
_addon.version = '1.2'

res = require('resources')
require 'healBot_curing'

local active = false
local actionDelay = 0.8
local minCureTier = 1
local rarr = string.char(129,168)
local npcs = S{'Joachim', 'Ulmia', 'Cherukiki'}

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
	elseif command == 'status' then
		printStatus()
	elseif command == 'info' then
		printInfo()
	else
		windower.add_to_chat(0, 'Error: Unknown command')
	end
end)

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
	if active then
		local now = os.clock()
		if (now - lastAction) >= actionDelay then
			actionDelay = 0.5
			local player = windower.ffxi.get_player()
			local hpTable = getMissingHps()
			local curee = getMemberWithMostHpMissing(hpTable)
			if (player ~= nil) and (curee ~= nil) and (not isTooFar(curee.name)) then
				local ncnum = get_tier_for_hp(curee.missing)
				if ncnum >= minCureTier then
					local spell = res.spells:with('en', ncures[ncnum])
					if (windower.ffxi.get_spell_recasts()[spell.recast_id] == 0) then
						windower.add_to_chat(0, "HealBot: "..spell.en.." "..rarr.." "..curee.name.."("..curee.missing..")")
						if (player.vitals.mp >= spell.mp_cost) then
							windower.send_command('input '..spell.prefix..' "'..spell.en..'" '..curee.name)
							actionDelay = spell.cast_time
						end
					else
						actionDelay = 0.3
					end
				end
			end
			lastAction = now
		end
	end
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