_addon.name = 'eventScripts'
_addon.author = 'Lorand'
_addon.commands = {'eventScripts', 'escripts'}
_addon.version = '0.2'

config = require('config')

local default_settings = {}
default_settings.login_cmds = {'wait 5; input /chatmode party'}
default_settings.addons = {['info']=true,['infoboxes']=true,['jponry']=true}
default_settings.reactions = {[3] = {['invitemenow_please'] = '/pcmd add {sender}'}}
local settings = config.load(default_settings)

local pname = nil

windower.register_event('chat message', function(message, sender, mode, gm)
	local reactions = settings.reactions[mode]
	if reactions == nil then return end
	local reaction = reactions[message:lower():gsub(' ', '_')]
	if reaction ~= nil then
		windower.send_command('input '..reaction:gsub('{sender}', sender))
	end
end)

windower.register_event('addon command', function(command,...)
	if pname == nil then return end
    command = command and command:lower() or 'help'
    local args = {...}
	
	if command == 'reload' then
		windower.send_command('lua unload '.._addon.name..'; lua load '.._addon.name)
	elseif command == 'unload' then
		windower.send_command('lua unload '.._addon.name)
	elseif command == 'addon' then
		changeAddons(args)
	else
		addonPrint('Error: Unknown command')
	end
	
	settings:save()
end)

function changeAddons(args)
	local cmd = args[1]:lower()
	local addon = args[2]:lower()
	
	if cmd == 'add' then
		settings[pname].addons[addon] = true
	elseif cmd == 'remove' then
		settings[pname].addons[addon] = false
	else
		settings[pname].addons[cmd] = true
	end
end

windower.register_event('login', 'load', function()
	local player = windower.ffxi.get_player()
	if player == nil then return end
	pname = player.name:lower()
	
	if not settings[pname] then
		settings[pname] = {login_cmds = {}, addons = {}, reactions = {}}
	end
	
	local login_cmds = merge(settings.login_cmds, settings[pname].login_cmds)
	for _,cmd in pairs(settings.login_cmds) do
		windower.send_command(cmd)
	end
	
	local addons = merge(settings.addons, settings[pname].addons)
	for addon,use in pairs(settings.addons) do
		local l = use and 'load ' or 'unload '
		windower.send_command('lua '..l..addon)
	end
end)

windower.register_event('logout', function()
	pname = nil
end)

function merge(...)
	local args = {...}
	local newtab = {}
	for _,t in pairs(args) do
		for k,v in pairs(t) do newtab[k] = v end
	end
	return newtab
end