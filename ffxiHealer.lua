_addon.name = 'ffxiHealer'
_addon.author = 'Lorand'
_addon.command = 'ffh'
_addon.version = '0.0.0.2'

require('luau')
res = require('resources')
require 'ffxiHealer_utilities'
require 'ffxiHealer_buffer'
require 'ffxiHealer_healer'

local debugMode = true
local casting = false
local myName = nil
local myID = nil

local players = {}			--Stores player information.  Key = name
local playerNames = {}		--Stores player names.  Key = ID

local enfeebling = T{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,155,156,157,158,159,167,168,174,175,177,186,189,192,193,194,223,259,260,261,262,263,264,298,378,379,380,386,387,388,389,390,391,392,393,394,395,396,397,398,399,400,404,448,449,450,451,452,473,540,557,558,559,560,561,562,563,564,565,566,567}
local rarr = string.char(129,168)

windower.register_event('addon command', function (command,...)
    command = command and command:lower() or 'help'
    local args = T{...}:map(string.lower)
	
	if command == 'reload' then
		windower.send_command('lua unload ffxiHealer; lua load ffxiHealer')
	elseif command == 'unload' then
		windower.send_command('lua unload ffxiHealer')
	elseif S{'remove','ignore'}:contains(command) then
		--Remove the given player names from the list of monitored players
		for _,arg in pairs(args) do
			arg = arg:lower():ucfirst()
			if table.containskey(players, arg) then
				playerNames[players[arg].id] = nil
				players[arg] = nil
				atc('Removed '..arg..' from the list of monitored players.')
			else
				atc('Error: '..arg..' was not in the list of monitored players.')
			end
		end
	elseif S{'add'}:contains(command) then
		--Add the given player name to the list of monitored players
		for _,arg in pairs(args) do
			initializePlayer(arg)
		end
	elseif command == 'status' then
		print_status()
	elseif S{'debuffs','ailments'}:contains(command) then
		atc('Current active debuffs:')
		for name,player in pairs(players) do
			print_table_keys(player.ailments, name..': ')
		end
	elseif S{'buffs'}:contains(command) then
		atc('Current active buffs:')
		for name,player in pairs(players) do
			print_table_keys(player.activeBuffs, name..': ')
		end
	else
		atc('Error: Unknown command')
	end
end)

windower.register_event('load','login',function ()
	atc('Initializing...')
	myName = windower.ffxi.get_player().name
	myID = windower.ffxi.get_player().id
	populate_players()
	print_status()
end)

windower.register_event('unload', function()
	atc('Shutting down.')
end)

windower.register_event('incoming chunk', function(id, data)
	if id == 0x028 then														--Action Packet
		local act = get_action_info(id, data)
		local actor = windower.ffxi.get_mob_by_id(act.actor_id).name
		
		for _,target in pairs(act.targets) do
			local tname = windower.ffxi.get_mob_by_id(target.id).name
			if table.containskey(players, tname) then						--If the spell target is being monitored...
				for _,tact in pairs(target.actions) do						--Iterate through the actions performed on the target
					atcd('[0x028]Action('..tact.message..'): '..actor..'['..act.actor_id..'] { '..act.param..' } '..rarr..' '..tname..'['..target.id..']'..' { '..tact.param..' }')
					
					if S{2}:contains(tact.message) then						--Magic damage
						local spell = res.spells[act.param]					--act.param: spell; tact.param: damage
						atcd(rarr..'  Magic damage; spell: '..spell.en)
						if S{230,231,232,233,234}:contains(act.param) then
							players[tname].ailments['Bio'] = os.clock()
						elseif S{23,24,25,26,27,33,34,35,36,37}:contains(act.param) then
							players[tname].ailments['Dia'] = os.clock()
						end
					elseif S{230}:contains(tact.message) then				--Gain status effect
						local buff = res.buffs[tact.param]
						atcd(rarr..'  Gain status effect: '..buff.en)
						players[tname].activeBuffs[buff.en] = os.clock()
					elseif S{341}:contains(tact.message) then				--Remove status ailment
						local buff = res.buffs[tact.param]
						atcd(rarr..'  Remove status ailment: '..buff.en)
						players[tname].ailments[buff.en] = nil
					end
				end
			end
		end
	elseif id == 0x029 then													--Action Message
		local am = get_action_info(id, data)
		local buff = res.buffs[am.param_1]
		local actor = windower.ffxi.get_mob_by_id(am.actor_id).name
		local target = windower.ffxi.get_mob_by_id(am.target_id).name
		
		if table.containskey(players, target) then							--If the spell target is being monitored...
			atcd('[0x029]Action Message('..am.message_id..'): '..actor..'['..am.actor_id..'] '..rarr..' '..target..'['..am.target_id..']'..' { '..tostring(am.param_1)..' | '..tostring(am.param_2)..' | '..tostring(am.param_3)..' }')
			
			if S{204,206}:contains(am.message_id) then						--Status effect/ailment wears off
				if enfeebling:contains(am.param_1) then
					players[target].ailments[buff] = nil
				else
					players[target].activeBuffs[buff] = nil
				end
				atcd(rarr..'  Registered status effect wearing off: '..buff.en)
			end
		end
	end
end)

function populate_players()
	for p,t in pairs(windower.ffxi.get_party()) do
		initializePlayer(t.name)
	end
end

function initializePlayer(name)
	name = name:lower():ucfirst()
	if table.containskey(players, name) then
		atc('Error: '..name..' is already being monitored.')
	else
		local player = windower.ffxi.get_mob_by_name(name)
		--TODO: Add anyways if its in windower.ffxi.get_party()
		if player ~= nil then
			players[name] = {
				id = player.id,
				buffs = {},
				activeBuffs = {},
				ailments = {}
			}
			playerNames[player.id] = player.name
			atc('Added '..player.name..' to the list of players to monitor.')
		else
			atc('Error: cannot add '..name..' to the list of monitored players.')
		end
	end
end

function atcd(text)
	if debugMode then atc(text) end
end

function print_status()
	print_table_keys(players, 'Currently monitoring: ')
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