_addon.name = 'autoWeaponskill'
_addon.author = 'Lorand'
_addon.command = 'autows'
_addon.version = '0.0.0.1'

useAutows = false
autoWsCmd = ''
autowsHpLt = true
autowsMobHp = 35
autowsDelay = 0.8
mobs = {}

windower.register_event('addon command', function (command,...)
    command = command and command:lower() or 'help'
    local args = {...}
	
	if command == 'reload' then
		windower.send_command('lua unload autoWeaponskill; lua load autoWeaponskill')
	elseif command == 'unload' then
		windower.send_command('lua unload autoWeaponskill')
	elseif command == 'toggle' then
		useAutows = not useAutows
		print_status()
	elseif command == 'set' then
		autoWsCmd = '/ws "'
		for i = 1, #args, 1 do
			autoWsCmd = autoWsCmd..args[i]
			if i < #args then
				autoWsCmd = autoWsCmd..' '
			end
		end
		autoWsCmd = autoWsCmd..'" <t>'
		print_status()
	elseif command == '<' then
		autowsHpLt = true
		print_status()
	elseif command == '>' then
		autowsHpLt = false
		print_status()
	elseif command == 'hp' then
		autowsMobHp = tonumber(args[1])
		print_status()
	elseif command == 'mob' then
		local mobName = ''
		for i = 3, #args, 1 do
			mobName = mobName..args[i]
			if i < #args then
				mobName = mobName..' '
			end
		end
		mobs[mobName] = {
			hp = tonumber(args[2]),
			sign = args[1]
		}
	elseif command == 'status' then
		print_status()
	elseif command == 'info' then
		printInfo()
	else
		windower.add_to_chat(0, 'Error: Unknown command')
	end
end)

windower.register_event('load', function()
	autowsLastCheck = os.clock()
	
	windower.add_to_chat(0, 'autoWeponskill commands:')
	windower.add_to_chat(0, 'autows mob <sign> <hp%> <name>')
	windower.add_to_chat(0, 'autows hp <hp%>')
	windower.add_to_chat(0, 'autows <')
	windower.add_to_chat(0, 'autows >')
	windower.add_to_chat(0, 'autows set <weaponskill name>')
	windower.add_to_chat(0, 'autows toggle')
	
	local player = windower.ffxi.get_player()
	if (player.name == 'Lorand') and (player.main_job == 'NIN') then
		windower.send_command('autows set Blade: Metsu')
		windower.send_command('autows toggle')
		windower.send_command('autows mob < 20 Slime Mold')
		windower.send_command('autows mob < 40 Phlebotomic Slug')
	end
	
end)

windower.register_event('prerender', function()
	if useAutows and (autoWsCmd ~= '') then
		local now = os.clock()
		if (now - autowsLastCheck) >= autowsDelay then
			local player = windower.ffxi.get_player()
			local mob = windower.ffxi.get_mob_by_target()
			
			if (player ~= nil) and (player.status == 1) and (mob ~= nil) then
				if mobs[mob.name] ~= nil then
					local signLt = (mobs[mob.name].sign == '<')
					local mobHp = mobs[mob.name].hp
					if (autowsMobHp ~= mobHp) or (autowsHpLt ~= signLt) then
						autowsHpLt = signLt
						windower.send_command('autows hp '..mobHp)
					end
				end
				
				if player.vitals.tp > 999 then
					if autowsHpLt then
						if mob.hpp < autowsMobHp then
							windower.send_command('input '..autoWsCmd)
						end
					else
						if mob.hpp > autowsMobHp then
							windower.send_command('input '..autoWsCmd)
						end
					end
				end
			end
			autowsLastCheck = now
		end
	end
end)

function print_status()
	local onoff = useAutows and 'On' or 'Off'
	local ltgt = autowsHpLt and '<' or '>'
	windower.add_to_chat(0, '[autoWeaponskill: '..onoff..'] {'..autoWsCmd..'} when target HP '..ltgt..' '..autowsMobHp..'%')
end

-----------------------------------------------------------------------------------------------------------
--[[
Copyright © 2014, Lorand
All rights reserved.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of ffxiHealer nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Lorand BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]
-----------------------------------------------------------------------------------------------------------