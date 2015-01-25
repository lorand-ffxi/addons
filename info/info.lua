_addon.name = 'info'
_addon.author = 'Lorand'
_addon.command = 'info'
_addon.version = '1.21'

require('luau')
res = require('resources')
packets = require('packets')

local showKB = false

windower.register_event('addon command', function (command,...)
    command = command or 'help'
    local args = {...}
	
	if command:lower() == 'reload' then
		windower.send_command('lua unload '.._addon.name..'; lua load '.._addon.name)
	elseif command:lower() == 'unload' then
		windower.send_command('lua unload '.._addon.name)
	elseif command:lower() == 'showkb' then
		showKB = not showKB
	else
		local cmd = parseInput(command)
		if cmd ~= nil then
			printInfo(cmd, command)
		else
			windower.add_to_chat(0, 'Error: Unable to parse valid command')
		end
	end
end)

windower.register_event('keyboard', function (dik, flags, blocked)
	if showKB then
		windower.add_to_chat(0, '[Keyboard] dik: '..tostring(dik)..', flags: '..tostring(flags)..', blocked: '..tostring(blocked))
	end
end)

function parseInput(command)
	if (command:startswith('type')) then
		local contents = command:sub(6, #command-1)
		local parsed = parseInput(contents)
		local asNum = tonumber(contents)
		if (#contents == 0) then
			contents = nil
		end
		local toType = parsed and parsed or (asNum and asNum or contents)
		return type(toType)
	end
	
	local parts = string.split(command, '.')
	local result = _G[parts[1]] or _G[parts[1]:lower()]
	
	for i = 2, #parts, 1 do
		if result == nil then return nil end
		local str = parts[i]
		if string.endswith(str, '()') then
			local func = str:sub(1, #str-2)
			result = result[func]()
		elseif string.endswith(str, ')') then
			local params = string.match(str, '%([^)]+%)')
			params = params:sub(2, #params-1)
			local func = str:sub(1, string.find(str, '%(')-1)
			result = result[func](params)
		elseif string.endswith(str, ']') then
			local key = string.match(str, '%[.+%]')
			key = key:sub(2, #key-1)
			local tab = str:sub(1, string.find(str, '%[')-1)
			result = result[tab][key]
		else
			local strnum = tonumber(str)
			if (strnum ~= nil) and (result[strnum] ~= nil) then
				result = result[strnum]
			else
				result = result[str]
			end
		end
	end
	
	return result
end

--[[
	Print all key, value pairs in the given table t to the FFXI chat log,
	with an optional header line h
--]]
function printInfo(t, h)
	if t ~= nil then
		if h ~= nil then
			windower.add_to_chat(2, h)
		end
		
		if type(t) == 'table' then
			for k,v in pairs(t) do
				windower.add_to_chat(0, tostring(k)..'  :  '..tostring(v))
			end
		else
			windower.add_to_chat(0, tostring(t))
		end
	end
end

-----------------------------------------------------------------------------------------------------------
--[[
Copyright © 2014, Lorand
All rights reserved.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of info nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Lorand BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]
-----------------------------------------------------------------------------------------------------------