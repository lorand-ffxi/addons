_addon.name = 'OhNoYouDont'
_addon.author = 'Lorand'
_addon.command = 'onyd'
_addon.version = '0.5'

--[[
	TODO:
	- Turn back around after mob finishes using gaze attack
	- Stun
	- Target by <t>, <bt>, or /as <player>
	- Interpret "<t>" as windower.ffxi.get_mob_by_target()
	- Save/load settings
--]]

require('luau')
res = require('resources')
local rarr = string.char(129,168)

local useStun = false
local useTurn = false
local watchFor = {}
local mobs = {}
local anyMob = true

windower.register_event('load', function()
	print_helptext()
end)

windower.register_event('addon command', function (command,...)
    command = command and command:lower() or 'help'
    local args = {...}
	
	if command == 'reload' then
		windower.send_command('lua unload '.._addon.name..'; lua load '.._addon.name)
	elseif command == 'unload' then
		windower.send_command('lua unload '.._addon.name)
	elseif command == 'turn' then
		useTurn = not useTurn
		print_status()
	elseif command == 'turnfor' then
		registerAbility(args, 'turn')
	elseif command == 'ignore' then
		registerAbility(args, 'ignore')
	elseif command == 'stun' then
		registerAbility(args, 'stun')
	elseif command == 'addmob' then
		registerMob(args, true)
	elseif command == 'ignoremob' then
		registerMob(args, false)
	elseif command == 'use' then
		addonPrint('Notice: "use" command not yet implemented.')
		--'onyd use <prefix> <spell/ability>
	else
		addonPrint('Error: Unknown command')
	end
end)

function print_status()
	addonPrint('Use stun: '..tostring(useStun)..' | Use turn: '..tostring(useTurn)..' | Any mob: '..tostring(anyMob))
end

function registerMob(name, add)
	local mobName = stringify(name)
	mobs[mobName] = add and true or nil
	addonPrint('Monitoring mob: '..mobName)
end

function registerAbility(ability, action)
	local abil = stringify(ability)
	local mobAbil = res.monster_abilities:with('en', abil)
	if mobAbil ~= nil then
		if action == 'ignore' then
			watchFor[mobAbil.id] = nil
			addonPrint('Ignoring '..abil)
		else
			watchFor[mobAbil.id] = {stun = (action == 'stun'), turn = (action == 'turn')}
			addonPrint('Will now '..action..(action == 'turn' and ' for ' or ' ')..abil)
		end
	else
		addonPrint('Unable to match "'..abil..'" with a valid monster ability.')
	end
end

windower.register_event('incoming chunk', function(id, data)
	if id == 0x028 then															--Action Packet
		local takeAction = false
		local act = get_action_info(id, data)
		local actor = windower.ffxi.get_mob_by_id(act.actor_id)
		
		if not actor.is_npc then return end
		
		local mobAbil
		
		if (not anyMob) and (mobs[actor.name] == nil) then return end
		
		for _,target in pairs(act.targets) do
			if not takeAction then
				local tname = windower.ffxi.get_mob_by_id(target.id).name
				for _,tact in pairs(target.actions) do							--Iterate through the actions performed on the target
					if not takeAction then
						mobAbil = res.monster_abilities[tact.param]
						if S{43, 326, 675}:contains(tact.message) and (watchFor[mobAbil.id] ~= nil) then
							takeAction = true
						end
					end
				end
			end
		end
		
		if takeAction then
			if watchFor[mobAbil.id].stun then
				windower.send_command('input /ja "Violent Flourish" <t>')
				addonPrint('Attempting to stun...')
				--windower.send_command('input '..stunCommand..' '..actor.name)
				--addonPrint('WARNING: '..mobAbil.en..' detected, but stunning has not yet been implemented!')
			elseif watchFor[mobAbil.id].turn then
				addonPrint('Notice: Turning away - '..mobAbil.en..' was detected!')
				windower.ffxi.turn(actor.heading)
			end
		end
	end
end)

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

function stringify(strTab)
	if strTab == nil then return nil end
	if type(strTab) == 'table' then
		local str = ''
		for i = 1, #strTab, 1 do
			str = str..strTab[i]
			if i < #strTab then
				str = str..' '
			end
		end
		return str
	else
		return strTab
	end
end

function print_helptext()
	windower.add_to_chat(0, _addon.name..' Commands:')
	windower.add_to_chat(0, 'onyd turn                :  Toggle turning upon ability detection')
	windower.add_to_chat(0, 'onyd turnfor <ability>  :  Turn when <ability> is detected')
	windower.add_to_chat(0, 'onyd stun <ability>     :  Stun when <ability> is detected')
	windower.add_to_chat(0, 'onyd addmob <name>   :  Add a mob to monitor for ability use')
end

function addonPrint(col, text)
	if text == nil then
		text = col
		col = 0
	end
	windower.add_to_chat(col, '['.._addon.name..'] '..text)
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