_addon.name = 'spellSpammer'
_addon.author = 'Lorand'
_addon.commands = {'spam','spellSpammer'}
_addon.version = '1.2.1'

local res = require('resources')
local config = require('config')
local aliases = config.load('..\\shortcuts\\data\\aliases.xml')
--local spellToSpam = 'Stone'
local spellsToSpam = {'Fire Threnody','Ice Threnody'}
local lastIndex = 0
local keepSpamming = false
local spamDelay = 0.8

windower.register_event('addon command', function (command,...)
    command = command and command:lower() or 'help'
    local args = {...}
	
	if command == 'reload' then
		windower.send_command('lua reload spellSpammer')
	elseif command == 'unload' then
		windower.send_command('lua unload spellSpammer')
	elseif S{'on','start'}:contains(command) then
		keepSpamming = true
		print_status()
	elseif S{'off','stop'}:contains(command) then
		keepSpamming = false
		print_status()
	elseif command == 'toggle' then
		keepSpamming = not keepSpamming
		print_status()
	elseif S{'use','cast'}:contains(command) then
		local arg_string = table.concat(args,' ')
		local spellName = formatSpellName(arg_string)
		local spell = res.spells:with('en', spellName)
		if (spell ~= nil) then
			if canCast(spell) then
				spellToSpam = spell.en
				atc(0,'Successfully changed spell to spam to: '..spell.en)
			else
				atc(123,'Error: Unable to cast '..spell.en)
			end
		else
			atc(123,'Error: Invalid spell name: '..arg_string..' | '..spellName)
		end
	elseif command == 'status' then
		print_status()
	else
		atc(123, 'Error: Unknown command')
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
			--local spell = res.spells:with('en', spellToSpam)
			local spell = get_spell()
			
			if (player ~= nil) and (player.status == 1) and (mob ~= nil) and (spell ~= nil) then
				if (windower.ffxi.get_spell_recasts()[spell.recast_id] == 0) then
					if (player.vitals.mp >= spell.mp_cost) and (mob.hpp > 0) then
						windower.send_command('input '..spell.prefix..' "'..spell.en..'" <t>')
						local add_delay = 1.6
						if (spell.recast >= 4) then
							add_delay = 0.2
						end
						spamDelay = spell.recast + add_delay + (math.random(2, 9)/10)
					end
				end
			end
			lastAttempt = now
		end
	end
end)

function sizeof(tbl)
	local c = 0
	for _,_ in pairs(tbl) do c = c + 1 end
	return c
end

function get_spell()
	local index = lastIndex + 1
	if (index < 1) or (index > sizeof(spellsToSpam)) then
		index = 1
	end
	local spell_name = spellsToSpam[index]
	local spell = res.spells:with('en', spell_name)
	lastIndex = index
	return spell
end

function print_status()
	local onoff = keepSpamming and 'On' or 'Off'
	windower.add_to_chat(0, '[spellSpammer: '..onoff..'] {'..spellToSpam..'}')
end

function atc(c, msg)
	if (type(c) == 'string') and (msg == nil) then
		msg = c
		c = 0
	end
	windower.add_to_chat(c, '[spellSpammer]'..msg)
end

function canCast(spell)
	if spell.prefix == '/magic' then
		local player = windower.ffxi.get_player()
		if (player == nil) or (spell == nil) then return false end
		local mainCanCast = (spell.levels[player.main_job_id] ~= nil) and (spell.levels[player.main_job_id] <= player.main_job_level)
		local subCanCast = (spell.levels[player.sub_job_id] ~= nil) and (spell.levels[player.sub_job_id] <= player.sub_job_level)
		local spellAvailable = windower.ffxi.get_spells()[spell.id]
		return spellAvailable and (mainCanCast or subCanCast)
	end
	return true
end

dec2roman = {'I','II','III','IV','V','VI','VII','VIII','IX','X','XI'}
roman2dec = {['I']=1,['II']=2,['III']=3,['IV']=4,['V']=5,['VI']=6,['VII']=7,['VIII']=8,['IX']=9,['X']=10,['XI']=11}

function formatSpellName(text)
	if (type(text) ~= 'string') or (#text < 1) then return nil end
	
	if (aliases ~= nil) then
		local fromAlias = aliases[text]
		if (fromAlias ~= nil) then
			return fromAlias
		end
	end
	
	local parts = text:split(' ')
	if #parts >= 2 then
		local name = formatName(parts[1])
		for p = 2, #parts do
			local part = parts[p]
			local tier = toRomanNumeral(part) or part:upper()
			if (roman2dec[tier] == nil) then
				name = name..' '..formatName(part)
			else
				name = name..' '..tier
			end
		end
		return name
	else
		local name = formatName(text)
		local tier = text:sub(-1)
		local rnTier = toRomanNumeral(tier)
		if (rnTier ~= nil) then
			return name:sub(1, #name-1)..' '..rnTier
		else
			return name
		end
	end
end

function formatName(text)
	if (text ~= nil) and (type(text) == 'string') then
		return text:lower():ucfirst()
	end
	return text
end

function toRomanNumeral(val)
	if type(val) ~= 'number' then
		if type(val) == 'string' then
			val = tonumber(val)
		else
			return nil
		end
	end
	return dec2roman[val]
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