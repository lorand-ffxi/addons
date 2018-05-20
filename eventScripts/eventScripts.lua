_addon.name = 'eventScripts'
_addon.author = 'Lorand'
_addon.commands = {'eventScripts', 'escripts'}
_addon.version = '0.3.2'
_addon.lastUpdate = '2018.05.19'

--[[
    EventScripts is a Windower addon for FFXI that is designed to provide both
    general and character-specific logon script functionality.  Additionally, it
    allows some level of event-based execution of commands like the old plugin
    AutoExec.  The included example of this feature is to send a party invite to
    a player after receiving a specific message in a tell from them.
--]]

local config = require('config')

local default_settings = {
    ['login_cmds'] = {'wait 5; input /chatmode party'},
    ['addons'] = {['info']=true,['infoboxes']=true,['jponry']=true},
    ['reactions'] = {[3] = {['invitemenow_please'] = '/pcmd add {sender}'}}
}
local settings = config.load(default_settings)
local pname = nil
local loaded_addons = {}

windower.register_event('chat message', function(message, sender, mode, gm)
    local lmessage = message:lower()
    local reactions = settings.reactions[mode]
    if reactions == nil then return end
    local modMessage = lmessage:gsub(' ', '_')
    local reaction = reactions[modMessage]
    if reaction ~= nil then
        windower.send_command('input '..reaction:gsub('{sender}', sender))
    elseif lmessage:contains('please') then
        local words = modMessage:split('_')
    end
end)

windower.register_event('addon command', function(command,...)
    if pname == nil then return end
    command = command and command:lower() or 'help'
    local args = {...}
    
    if command == 'reload' then
        windower.send_command('lua reload '.._addon.name)
    elseif command == 'unload' then
        windower.send_command('lua unload '.._addon.name)
    elseif command == 'addon' then
        changeAddons(args)
    else
        addonPrint('Error: Unknown command')
    end
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
    settings:save('all')
end

windower.register_event('login', 'load', function()
    local player = windower.ffxi.get_player()
    if player == nil then
        windower.send_command("config FrameRateDivisor 1")
        return
    end
    pname = player.name:lower()

    if not settings[pname] then
        settings[pname] = {login_cmds = {}, addons = {}, reactions = {}}
    end
    
    local login_cmds = merge(settings.login_cmds, settings[pname].login_cmds)
    for _,cmd in pairs(login_cmds) do
        windower.send_command(cmd)
    end
    
    local addons = merge(settings.addons, settings[pname].addons)
    for addon, should_load in pairs(addons) do
        if should_load then
            if (loaded_addons[addon] == nil) or (not loaded_addons[addon]) then
                windower.send_command('lua load '..addon)
                loaded_addons[addon] = true
            end
        else
            if (loaded_addons[addon] == nil) or loaded_addons[addon] then
                windower.send_command('lua unload '..addon)
                loaded_addons[addon] = false
            end
        end
    end
end)

windower.register_event('logout', function()
    pname = nil
    windower.send_command("config FrameRateDivisor 1")
end)

function merge(...)
    local args = {...}
    local newtab = {}
    for _,t in pairs(args) do
        for k,v in pairs(t) do newtab[k] = v end
    end
    return newtab
end

-----------------------------------------------------------------------------------------------------------
--[[
Copyright © 2016, Lorand
All rights reserved.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of eventScripts nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Lorand BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]
-----------------------------------------------------------------------------------------------------------
