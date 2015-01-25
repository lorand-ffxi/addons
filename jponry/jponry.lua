_addon.name = 'jponry'
_addon.author = 'Lorand'
_addon.command = 'jponry'
_addon.version = '1.2'

chars = require('chat.chars')

local charsb = {['j^'] = string.char(129, 79)}

local rchars = {
	['rf'] = string.char(132, 112),	['r,'] = string.char(132, 113),	['rd'] = string.char(132, 114),	['ru'] = string.char(132, 115),	['rl'] = string.char(132, 116),	
	['rt'] = string.char(132, 117),	['r\\'] = string.char(132, 118),['r;'] = string.char(132, 119),	['rp'] = string.char(132, 120),	['rb'] = string.char(132, 121),
	['rq'] = string.char(132, 122),	['rr'] = string.char(132, 123),	['rk'] = string.char(132, 124),	['rv'] = string.char(132, 125),	['ry'] = string.char(132, 126),
	['rj'] = string.char(132, 127),	['rg'] = string.char(132, 129),	['rh'] = string.char(132, 130),	['rc'] = string.char(132, 131),	['rn'] = string.char(132, 132),
	['re'] = string.char(132, 133),	['ra'] = string.char(132, 134),	['r['] = string.char(132, 135),	['rw'] = string.char(132, 136),	['rx'] = string.char(132, 137),	
	['ri'] = string.char(132, 138),	['ro'] = string.char(132, 139),	['r]'] = string.char(132, 140),	['rs'] = string.char(132, 141),	['rm'] = string.char(132, 142),
	['r\''] = string.char(132, 143),['r.'] = string.char(132, 144),	['rz'] = string.char(132, 145),
	['rF'] = string.char(132, 64),	['r<'] = string.char(132, 65),	['rD'] = string.char(132, 66),	['rU'] = string.char(132, 67),	['rL'] = string.char(132, 68),
	['rT'] = string.char(132, 69),	['r|'] = string.char(132, 70),	['r:'] = string.char(132, 71),	['rP'] = string.char(132, 72),	['rB'] = string.char(132, 73),
	['rQ'] = string.char(132, 74),	['rR'] = string.char(132, 75),	['rK'] = string.char(132, 76),	['rV'] = string.char(132, 77),	['rY'] = string.char(132, 78),
	['rJ'] = string.char(132, 79),	['rG'] = string.char(132, 80),	['rH'] = string.char(132, 81),	['rC'] = string.char(132, 82),	['rN'] = string.char(132, 83),
	['rE'] = string.char(132, 84),	['rA'] = string.char(132, 85),	['r{'] = string.char(132, 86),	['rW'] = string.char(132, 87),	['rX'] = string.char(132, 88),
	['rI'] = string.char(132, 89),	['rO'] = string.char(132, 90),	['r}'] = string.char(132, 91),	['rS'] = string.char(132, 92),	['rM'] = string.char(132, 93),
	['r"'] = string.char(132, 94),	['r>'] = string.char(132, 95),	['rZ'] = string.char(132, 96),
}

windower.register_event('addon command', function (command,...)
    command = command or 'help'
    local args = {...}
	
	if command:lower() == 'reload' then
		windower.send_command('lua unload '.._addon.name..'; lua load '.._addon.name)
	elseif command:lower() == 'unload' then
		windower.send_command('lua unload '.._addon.name)
	elseif command:lower() == 'chars' then
		for k,v in pairs(chars) do
			windower.add_to_chat(1, v..' : '..k)
		end
	elseif command:lower() == 'char' then
		printChar(args)
	elseif command:lower() == 'printchars' then
		printChars(args)
	elseif command:lower() == 'r' then
		convert(args, 'r')
	else
		convert(args, 'j', command)
	end
end)

function convert(words, mode, chatmode)
	local w1 = 1
	if chatmode == nil then
		chatmode = words[1]
		w1 = 2
	end
	if chatmode == '/t' then
		chatmode = '/t '..words[w1]
		w1 = w1 + 1
	end

	local charmap = merge(chars, charsb, rchars)
	
	local text = ''
	for i = w1, #words, 1 do
		for c in words[i]:gmatch('.') do
			if charmap[mode..c] ~= nil then
				text = text..charmap[mode..c]
			else
				text = text..c
			end
		end
		if i < #words then
			text = text..' '
		end
	end
	if text ~= '' then
		windower.send_command('input '..chatmode..' '..text)
	end
end

function merge(...)
	local args = {...}
	local newtab = {}
	for _,t in pairs(args) do
		for k,v in pairs(t) do newtab[k] = v end
	end
	return newtab
end

function printChar(args)
	local a = tonumber(args[1])
	local b = tonumber(args[2])
	local c = string.char(a, b)
	
	if c ~= nil then
		windower.add_to_chat(1, c..' = string.char('..a..', '..b..')')
	else
		windower.add_to_chat(1, 'Invalid character code: ('..a..', '..b..')')
	end
end

function printChars(args)
	local a = tonumber(args[1])
	
	for i = 1, 255, 1 do
		local c = string.char(a, i)
		if c ~= nil then
			windower.add_to_chat(1, c..' = string.char('..a..', '..i..')')
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
    * Neither the name of ffxiHealer nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Lorand BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]
-----------------------------------------------------------------------------------------------------------