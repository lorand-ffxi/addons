local romanNumerals = {'I','II','III','IV','V','VI','VII','VIII','IX','X','XI'}

function get_bit_packed(dat_string,start,stop)
	--Copied from Battlemod; thanks to Byrth / SnickySnacks
	local newval = 0   
	local c_count = math.ceil(stop/8)
	while c_count >= math.ceil((start+1)/8) do
		local cur_val = dat_string:byte(c_count)
		local scal = 256
		if c_count == math.ceil(stop/8) then
			cur_val = cur_val%(2^((stop-1)%8+1))
		end
		if c_count == math.ceil((start+1)/8) then
			cur_val = math.floor(cur_val/(2^(start%8)))
			scal = 2^(8-start%8)
		end
		newval = newval*scal + cur_val
		c_count = c_count - 1
	end
	return newval
end

function print_action_info(act)
	local actionPerformer = windower.ffxi.get_mob_by_id(act.actor_id).name
	atc('Incoming action by '..actionPerformer..' ['..act.actor_id..']:  { category : '..act.category..' | recast : '..act.recast..' | param : '..act.param..' }')
	for k,v in pairs(act.targets) do
		local actionTarget = windower.ffxi.get_mob_by_id(v.id).name
		atc(' '..rarr..' '..actionTarget..' ['..v.id..']')
		for l,b in pairs(v.actions) do
			atc('      message : '..b.message..' | param : '..b.param)
		end
	end
end

function formatSpellName(text)
	if (type(text) ~= 'string') or (#text < 1) then return nil end
	
	local fromAlias = aliases[text]
	if (fromAlias ~= nil) then
		return fromAlias
	end
	
	local parts = text:split(' ')
	if #parts > 2 then
		return nil
	elseif #parts == 2 then
		local name = formatName(parts[1])
		local tier = toRomanNumeral(parts[2])
		tier = tier and tier or parts[2]:upper()
		return name..' '..tier
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
	return romanNumerals[val]
end

function atc(text)
	windower.add_to_chat(0, '[healBot]'..text)
end

function atcd(text)
	if debugMode then atc(text) end
end

function print_table_keys(t, prefix)
	prefix = prefix or ''
	local msg = ''
	for k,v in pairs(t) do
		if #msg > 0 then msg = msg..', ' end
		msg = msg..k
	end
	if #msg == 0 then msg = '(none)' end
	atc(prefix..msg)
end

function printPairs(tbl, prefix)
	if prefix == nil then prefix = '' end
	for k,v in pairs(tbl) do
		atc(prefix..tostring(k)..' : '..tostring(v))
		if type(v) == 'table' then
			printPairs(v, prefix..'    ')
		end
	end
end

--Extracts useful information from a given packet
function get_action_info(id, data)
	--Modified from Battlemod's 'incoming chunk' function; thanks to Byrth / SnickySnacks
    local pref = data:sub(1,4)
    local data = data:sub(5)
	
    if id == 0x28 then			-------------- ACTION PACKET ---------------
        local act = {}
        act.do_not_need = get_bit_packed(data,0,8)
        act.actor_id = get_bit_packed(data,8,40)
        act.target_count = get_bit_packed(data,40,50)
        act.category = get_bit_packed(data,50,54)
        act.param = get_bit_packed(data,54,70)
        act.unknown = get_bit_packed(data,70,86)
        act.recast = get_bit_packed(data,86,118)
        act.targets = {}
        local offset = 118
        for i = 1,act.target_count do
            act.targets[i] = {}
            act.targets[i].id = get_bit_packed(data,offset,offset+32)
            act.targets[i].action_count = get_bit_packed(data,offset+32,offset+36)
            offset = offset + 36
            act.targets[i].actions = {}
            for n = 1,act.targets[i].action_count do
                act.targets[i].actions[n] = {}
                act.targets[i].actions[n].reaction = get_bit_packed(data,offset,offset+5)
                act.targets[i].actions[n].animation = get_bit_packed(data,offset+5,offset+16)
                act.targets[i].actions[n].effect = get_bit_packed(data,offset+16,offset+21)
                act.targets[i].actions[n].stagger = get_bit_packed(data,offset+21,offset+27)
                act.targets[i].actions[n].param = get_bit_packed(data,offset+27,offset+44)
                act.targets[i].actions[n].message = get_bit_packed(data,offset+44,offset+54)
                act.targets[i].actions[n].unknown = get_bit_packed(data,offset+54,offset+85)
                act.targets[i].actions[n].has_add_effect = get_bit_packed(data,offset+85,offset+86)
                offset = offset + 86
                if act.targets[i].actions[n].has_add_effect == 1 then
                    act.targets[i].actions[n].has_add_effect = true
                    act.targets[i].actions[n].add_effect_animation = get_bit_packed(data,offset,offset+6)
                    act.targets[i].actions[n].add_effect_effect = get_bit_packed(data,offset+6,offset+10)
                    act.targets[i].actions[n].add_effect_param = get_bit_packed(data,offset+10,offset+27)
                    act.targets[i].actions[n].add_effect_message = get_bit_packed(data,offset+27,offset+37)
                    offset = offset + 37
                else
                    act.targets[i].actions[n].has_add_effect = false
                    act.targets[i].actions[n].add_effect_animation = 0
                    act.targets[i].actions[n].add_effect_effect = 0
                    act.targets[i].actions[n].add_effect_param = 0
                    act.targets[i].actions[n].add_effect_message = 0
                end
                act.targets[i].actions[n].has_spike_effect = get_bit_packed(data,offset,offset+1)
                offset = offset +1
                if act.targets[i].actions[n].has_spike_effect == 1 then
                    act.targets[i].actions[n].has_spike_effect = true
                    act.targets[i].actions[n].spike_effect_animation = get_bit_packed(data,offset,offset+6)
                    act.targets[i].actions[n].spike_effect_effect = get_bit_packed(data,offset+6,offset+10)
                    act.targets[i].actions[n].spike_effect_param = get_bit_packed(data,offset+10,offset+24)
                    act.targets[i].actions[n].spike_effect_message = get_bit_packed(data,offset+24,offset+34)
                    offset = offset + 34
                else
                    act.targets[i].actions[n].has_spike_effect = false
                    act.targets[i].actions[n].spike_effect_animation = 0
                    act.targets[i].actions[n].spike_effect_effect = 0
                    act.targets[i].actions[n].spike_effect_param = 0
                    act.targets[i].actions[n].spike_effect_message = 0
                end
            end
        end
        return act
    elseif id == 0x29 then		----------- ACTION MESSAGE ------------
		local am = {}
		am.actor_id = get_bit_packed(data,0,32)
		am.target_id = get_bit_packed(data,32,64)
		am.param_1 = get_bit_packed(data,64,96)
		am.param_2 = get_bit_packed(data,96,106) -- First 6 bits
		am.param_3 = get_bit_packed(data,106,128) -- Rest
		am.actor_index = get_bit_packed(data,128,144)
		am.target_index = get_bit_packed(data,144,160)
		am.message_id = get_bit_packed(data,160,175) -- Cut off the most significant bit, hopefully
		return am
	end
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