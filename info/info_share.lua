--==============================================================================
--		Functions that can be shared with other addons
--==============================================================================

info = {}

function info.process_input(command, args)
	if S{'search','with','find'}:contains(command:lower()) then
		local target = args[1]
		local field = args[2]
		local val = args[3]
		if (target ~= nil) and (field ~= nil) and (val ~= nil) then
			local parsed = info.parse_for_info(target)
			local results = parsed:with(field, val)
			if (results ~= nil) then
				info.print_table(parsed:with(field, val), target..':with('..field..','..val..')')
			else
				atc(2, target..':with('..field..','..val..'): No results.')
			end
		else
			atc(0, 'Error: Invalid arguments passed for search')
		end
	elseif command:lower() == 'spells' then
		local stype = args[1]
		atc(0, 'spell_id,spell_name,element,skill')
		for k,v in pairs(res.spells) do
			if v.type == stype then
				atc(0, v.id..','..v.en..','..v.element..','..v.skill)
			end
		end
	elseif command:lower() == 'colortest' then
		for c = 0, 256 do
			atc(c, 'color test: '..c)
		end
	else
		local parsed = info.parse_for_info(command)
		if parsed ~= nil then
			local msg = ':'
			if (type(parsed) == 'table') then
				msg = ' ('..sizeof(parsed)..'):'
			end
			info.print_table(parsed, command..msg)
		else
			atc(3,'Error: Unable to parse valid command')
		end
	end
end

--[[
	Parses the given command for table names or functions, then returns the
	result of executing the given function, or table or value with the
	given name.
--]]
function info.parse_for_info(command)
	if (command:startswith('type')) then
		local contents = command:sub(6, #command-1)
		local parsed = parse_for_info(contents)
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

function sizeof(tbl)
	local c = 0
	for _,_ in pairs(tbl) do c = c + 1 end
	return c
end

--[[
	Print all key, value pairs in the given table to the FFXI chat log,
	with an optional header line
--]]
function info.print_table(tbl, header)
	if tbl ~= nil then
		if header ~= nil then
			atc(2, header)
		end
		if type(tbl) == 'table' then
			local c = 0
			for k,v in pairs(tbl) do
				atc(0, tostring(k)..'  :  '..tostring(v))
				c = c + 1
				if ((c % 50) == 0) then
					atc(160,'---------- ('..c..') ----------')
				end
			end
		else
			atc(0, tostring(tbl))
		end
	end
end

return info

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