_addon.name = 'GMmode'
_addon.author = 'Lorand'
_addon.command = 'gmm'
_addon.version = '1.0'

packets = require('packets')

local flags = {['POL']=0x60, ['GM']=0x80, ['GM1']=0x80, ['GM2']=0xA0, ['GM3']=0xC0, ['SGM']=0xE0}
local flagMap = {[0x60]='POL', [0x80]='GM1', [0xA0]='GM2', [0xC0]='GM3', [0xE0]='SGM'}
local useFlag = 0xE0

windower.register_event('addon command', function (command,...)
    command = command and command:lower() or 'help'
    local args = {...}
	
	if command == 'reload' then
		windower.send_command('lua reload GMmode')
	elseif command == 'unload' then
		windower.send_command('lua unload GMmode')
	elseif S{'use', 'flag', 'useflag', 'set', 'setflag'}:contains(command) then
		if args[1] ~= nil then
			local flagType = args[1]:upper()
			if flags[flagType] then
				useFlag = flags[flagType]
				atc('Flag set to '..flagType..'. Rest to update your character.')
			else
				atc('Error: Invalid flag name.')
				helpText()
			end
		else
			atc('Error: No flag name was provided.')
			helpText()
		end
	else
		helpText()
	end
end)

windower.register_event('incoming chunk',function (id, data)
	if id == 0x037 then
		local parsed = packets.parse('incoming', data)
		local plyr = windower.ffxi.get_player()
		if (parsed.Player == plyr.id) then
			parsed._flags2 = useFlag
			local rebuilt = packets.build(parsed)
			return rebuilt
		end
	end
end)

function atc(text)
	windower.add_to_chat(0, '[GMmode]'..text)
end

function helpText()
	atc('//gmm use flagName     :     Use flag flagName')
	atc('Valid flags: POL, GM, GM2, GM3, SGM')
	atc('Current flag: '..flagMap[useFlag])
end