_addon.name = 'OhNoYouDont'
_addon.author = 'Lorand'
_addon.command = 'onyd'
_addon.version = '0.6'
_addon.lastUpdate = '2015.02.12'

--[[
	TODO:
	- Turn back around after mob finishes using gaze attack
	- Stun
	- Target by <t>, <bt>, or /as <player>
	- Interpret "<t>" as windower.ffxi.get_mob_by_target()
	- Save/load settings
--]]

require('luau')
local res = require('resources')
local config = require('config')
local rarr = string.char(129,168)

local abil_start_ids = S{43,326,675}
local spell_start_ids = S{3,327,716}

local msgMap = {['turn']='turn for',['stun']='stun'}

local defaults = {}
defaults.profile = {}
defaults.profile.shark = {}
defaults.profile.shark.stun = {'Protolithic Puncture','Pelagic Cleaver','Tidal Guillotine','Carcharian Verve','Marine Mayhem','Aquatic Lance'}
local settings = config.load(defaults)

local profile = {}
local enabled = false
local debugging = true

windower.register_event('load', function()
	print_helptext()
end)

windower.register_event('logout', function()
	windower.send_command('lua unload '.._addon.name)
end)

windower.register_event('addon command', function (command,...)
	command = command and command:lower() or 'help'
	local args = {...}
	
	if command == 'reload' then
		windower.send_command('lua reload '.._addon.name)
	elseif command == 'unload' then
		windower.send_command('lua unload '.._addon.name)
	elseif command == 'load' then
		if (args[1] ~= nil) then
			if (settings.profile[args[1]] ~= nil) then
				loadProfile(args[1])
			else 
				atc('ERROR: Profile "'..args[1]..'" does not exist.')
			end
		else
			atc('ERROR: No profile name provided to load.')
		end
	elseif S{'enable','on','start'}:contains(command) then
		enabled = true
		print_status()
	elseif S{'disable','off','stop'}:contains(command) then
		enabled = false
		atc('Disabled.')
	elseif command == 'status' then
		print_status()
	else
		atc('ERROR: Unknown command')
	end
end)

function loadProfile(pname)
	profile.name = pname
	profile.stun = S{}
	profile.turn = S{}
	for action,skills in pairs(settings.profile[pname]) do
		for _,skill in pairs(skills) do
			local mabil = res.monster_abilities:with('en', skill)
			if (mabil ~= nil) then
				profile[action]:add(mabil.id)
			else
				atc('ERROR: Unable to '..msgMap[action]..' '..skill)
			end
		end
	end
	atc('Loaded profile: '..pname)
	print_status()
end

function print_status()
	local pname = profile.name or '(none)'
	local etxt = enabled and 'ACTIVE' or 'DISABLED'
	atc('Profile loaded: '..pname..' ['..etxt..']')
	
	--printTable(profile.stun, 'profile.stun')
	
	local stunning = ''
	local c = 0
	for abilid,_ in pairs(profile.stun) do
		local mabil = res.monster_abilities[abilid].en
		if c > 0 then
			stunning = stunning..', '
		end
		stunning = stunning..mabil
		c = c + 1
	end
	if stunning == '' then
		stunning = '(nothing)'
	end
	atc('Stunning: '..stunning)
	
	local turning = ''
	c = 0
	for abilid,_ in pairs(profile.turn) do
		local mabil = res.monster_abilities[abilid].en
		if c > 0 then
			turning = turning..', '
		end
		turning = turning..mabil
		c = c + 1
	end
	if turning == '' then
		turning = '(nothing)'
	end
	atc('Turning for: '..turning)
end

function processAction(m_id, a_id)
	if abil_start_ids:contains(m_id) then
		local player = windower.ffxi.get_player()
		local target = windower.ffxi.get_mob_by_target()
		local mabil = res.monster_abilities[a_id]
		local abilname = mabil and mabil.en or '(unknown)'
		
		if profile.turn:contains(a_id) then
			windower.ffxi.turn(target.facing)
			atc('Alert: Turning for '..abilname..'!')
			return true
		elseif profile.stun:contains(a_id) then
			local stunCmd = ''
			if S{'BLM','DRK'}:contains(player.main_job) or S{'BLM','DRK'}:contains(player.sub_job) then
				stunCmd = '/ma Stun <t>'
			elseif S{player.main_job,player.sub_job}:contains('DNC') then
				stunCmd = '/ja "Violent Flourish" <t>'
			else
				atc('ERROR: Job combo has no abilities available to stun '..abilname)
			end
			if (#stunCmd > 1) then
				windower.send_command('input '..stunCmd)
			end
			return true
		else
			atcd('No action to perform for '..abilname..' [id: '..a_id..']')
		end
	end
	return false	
end

windower.register_event('incoming chunk', function(id, data)
	if enabled and (id == 0x28) then
		local ai = get_action_info(id, data)
		local actor = windower.ffxi.get_mob_by_id(ai.actor_id)
		local target = windower.ffxi.get_mob_by_target()
		if (actor.is_npc) and (target ~= nil) and (target.id == ai.actor_id) then
			for _,targ in pairs(ai.targets) do
				for _,tact in pairs(targ.actions) do
					if abil_start_ids:contains(tact.message_id) then
						--if processAction(tact.message_id, ai.param) then
						if processAction(tact.message_id, tact.param) then
							return
						end
					--elseif spell_start_ids:contains(tact.message_id) then
					end
				end
			end
		end
	end
end)

--[[
	Parse the given packet and construct a table to make its contents useful.
	Based on the 'incoming chunk' function in the Battlemod addon (thanks to Byrth / SnickySnacks)
	@param id packet ID
	@param data raw packet contents
	@return a table representing the given packet's data
--]]
function get_action_info(id, data)
	local pref = data:sub(1,4)
	local data = data:sub(5)
	if id == 0x28 then			-------------- ACTION PACKET ---------------
		local act = {}
		act.do_not_need	= get_bit_packed(data,0,8)
		act.actor_id	= get_bit_packed(data,8,40)
		act.target_count= get_bit_packed(data,40,50)
		act.category	= get_bit_packed(data,50,54)
		act.param	= get_bit_packed(data,54,70)
		act.unknown	= get_bit_packed(data,70,86)
		act.recast	= get_bit_packed(data,86,118)
		act.targets = {}
		local offset = 118
		for i = 1, act.target_count do
			act.targets[i] = {}
			act.targets[i].id = get_bit_packed(data,offset,offset+32)
			act.targets[i].action_count = get_bit_packed(data,offset+32,offset+36)
			offset = offset + 36
			act.targets[i].actions = {}
			for n = 1,act.targets[i].action_count do
				act.targets[i].actions[n] = {}
				act.targets[i].actions[n].reaction	= get_bit_packed(data,offset,offset+5)
				act.targets[i].actions[n].animation	= get_bit_packed(data,offset+5,offset+16)
				act.targets[i].actions[n].effect	= get_bit_packed(data,offset+16,offset+21)
				act.targets[i].actions[n].stagger	= get_bit_packed(data,offset+21,offset+27)
				act.targets[i].actions[n].param		= get_bit_packed(data,offset+27,offset+44)
				act.targets[i].actions[n].message_id	= get_bit_packed(data,offset+44,offset+54)
				act.targets[i].actions[n].unknown	= get_bit_packed(data,offset+54,offset+85)
				act.targets[i].actions[n].has_add_efct	= get_bit_packed(data,offset+85,offset+86)
				offset = offset + 86
				if act.targets[i].actions[n].has_add_efct == 1 then
					act.targets[i].actions[n].has_add_efct		= true
					act.targets[i].actions[n].add_efct_animation	= get_bit_packed(data,offset,offset+6)
					act.targets[i].actions[n].add_efct_effect	= get_bit_packed(data,offset+6,offset+10)
					act.targets[i].actions[n].add_efct_param	= get_bit_packed(data,offset+10,offset+27)
					act.targets[i].actions[n].add_efct_message_id	= get_bit_packed(data,offset+27,offset+37)
					offset = offset + 37
				else
					act.targets[i].actions[n].has_add_efct		= false
					act.targets[i].actions[n].add_efct_animation	= 0
					act.targets[i].actions[n].add_efct_effect	= 0
					act.targets[i].actions[n].add_efct_param	= 0
					act.targets[i].actions[n].add_efct_message_id	= 0
				end
				act.targets[i].actions[n].has_spike_efct = get_bit_packed(data,offset,offset+1)
				offset = offset + 1
				if act.targets[i].actions[n].has_spike_efct == 1 then
					act.targets[i].actions[n].has_spike_efct	= true
					act.targets[i].actions[n].spike_efct_animation	= get_bit_packed(data,offset,offset+6)
					act.targets[i].actions[n].spike_efct_effect	= get_bit_packed(data,offset+6,offset+10)
					act.targets[i].actions[n].spike_efct_param	= get_bit_packed(data,offset+10,offset+24)
					act.targets[i].actions[n].spike_efct_message_id	= get_bit_packed(data,offset+24,offset+34)
					offset = offset + 34
				else
					act.targets[i].actions[n].has_spike_efct	= false
					act.targets[i].actions[n].spike_efct_animation	= 0
					act.targets[i].actions[n].spike_efct_effect	= 0
					act.targets[i].actions[n].spike_efct_param	= 0
					act.targets[i].actions[n].spike_efct_message_id	= 0
				end
			end
		end
		return act
	elseif id == 0x29 then		----------- ACTION MESSAGE ------------
		local am = {}
		am.actor_id	= get_bit_packed(data,0,32)
		am.target_id	= get_bit_packed(data,32,64)
		am.param_1	= get_bit_packed(data,64,96)
		am.param_2	= get_bit_packed(data,96,106)	-- First 6 bits
		am.param_3	= get_bit_packed(data,106,128)	-- Rest
		am.actor_index	= get_bit_packed(data,128,144)
		am.target_index	= get_bit_packed(data,144,160)
		am.message_id	= get_bit_packed(data,160,175)	-- Cut off the most significant bit, hopefully
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
	atc('Commands:')
	atc('onyd load <profile name> : load profile <profile name>')
end

function printTable(tbl, header)
	if header ~= nil then
		atc('Printing table: '..header)
	end
	for k,v in pairs(tbl) do
		windower.add_to_chat(0, tostring(k)..'  :  '..tostring(v))
	end
end

function atc(text)
	windower.add_to_chat(0, '['.._addon.name..'] '..text)
end

function atcd(text)
	if debugging then
		atc(text)
	end
end

-----------------------------------------------------------------------------------------------------------
--[[
Copyright © 2015, Lorand
All rights reserved.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of OhNoYouDont nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Lorand BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]
-----------------------------------------------------------------------------------------------------------