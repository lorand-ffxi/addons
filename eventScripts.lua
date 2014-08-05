_addon.name = 'eventScripts'
_addon.author = 'Lorand'
_addon.command = 'sventScripts'
_addon.version = '0.0.0.1'

windower.register_event('login',function ()
	windower.send_command('wait 5; input /chatmode party')
end)