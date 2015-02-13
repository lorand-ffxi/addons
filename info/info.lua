_addon.name = 'info'
_addon.author = 'Lorand'
_addon.command = 'info'
_addon.version = '1.4'
_addon.lastUpdate = '2015.02.13'

--[[
	Info is a Windower addon for FFXI that is designed to allow users to view
	data that is available to Windower from within the game.
--]]

require('luau')
res = require('resources')
packets = require('packets')

require 'info_share'

local showKB = false
local showAnActionPacket = false

windower.register_event('addon command', function (command,...)
    command = command or 'help'
    local args = {...}
	
	if command:lower() == 'reload' then
		windower.send_command('lua reload '.._addon.name)
	elseif command:lower() == 'unload' then
		windower.send_command('lua unload '.._addon.name)
	elseif command:lower() == 'showkb' then
		showKB = not showKB
	elseif command:lower() == 'actionpacket' then
		showAnActionPacket = true
	else
		info.process_input(command, args)
	end
end)

windower.register_event('incoming chunk', function(id,data)
	if showAnActionPacket then
		if id == 0x28 then
			local parsed = packets.parse('incoming', data)
			print_table(parsed, 'Action Packet (0x028)')
			if parsed['Target 1 Action 1 Message'] == 230 then
				showAnActionPacket = false
			end
		end
	end
end)

windower.register_event('keyboard', function (dik, flags, blocked)
	if showKB then
		atc('[Keyboard] dik: '..tostring(dik)..', flags: '..tostring(flags)..', blocked: '..tostring(blocked))
	end
end)

function atc(c, msg)
	if (type(c) == 'string') and (msg == nil) then
		msg = c
		c = 0
	end
	windower.add_to_chat(c, msg)
end

-----------------------------------------------------------------------------------------------------------
--[[
Copyright © 2014-2015, Lorand
All rights reserved.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of info nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Lorand BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]
-----------------------------------------------------------------------------------------------------------