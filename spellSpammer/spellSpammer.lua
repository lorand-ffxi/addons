_addon.name = 'spellSpammer'
_addon.author = 'Lorand'
_addon.command = 'spellSpammer'
_addon.version = '1.0'

res = require('resources')
spellToSpam = 'Stone'
keepSpamming = false
spamDelay = 0.8

windower.register_event('addon command', function (command,...)
    command = command and command:lower() or 'help'
    local args = {...}
	
	if command == 'reload' then
		windower.send_command('lua unload spellSpammer; lua load spellSpammer')
	elseif command == 'unload' then
		windower.send_command('lua unload spellSpammer')
	elseif command == 'toggle' then
		keepSpamming = not keepSpamming
		print_status()
	elseif command == 'status' then
		print_status()
	else
		windower.add_to_chat(0, 'Error: Unknown command')
	end
end)

windower.register_event('load', function()
	lastAttempt = os.clock()
end)

windower.register_event('prerender', function()
	if keepSpamming then
		local now = os.clock()
		if (now - lastAttempt) >= spamDelay then
			local player = windower.ffxi.get_player()
			local mob = windower.ffxi.get_mob_by_target()
			local spell = res.spells:with('en', spellToSpam)
			
			if (player ~= nil) and (player.status == 1) and (mob ~= nil) then
				if (windower.ffxi.get_spell_recasts()[spell.recast_id] == 0) then
					if (player.vitals.mp >= spell.mp_cost) and (mob.hpp > 0) then
						windower.send_command('input '..spell.prefix..' "'..spell.en..'" <t>')
						spamDelay = spell.recast + 1.6 + (math.random(2, 9)/10)
					end
				end
			end
			lastAttempt = now
		end
	end
end)

function print_status()
	local onoff = keepSpamming and 'On' or 'Off'
	windower.add_to_chat(0, '[spellSpammer: '..onoff..'] {'..spellToSpam..'}')
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