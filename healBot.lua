_addon.name = 'healBot'
_addon.author = 'Lorand'
_addon.command = 'hb'
_addon.version = '1.0'

res = require('resources')
active = false
actionDelay = 0.8

local rarr = string.char(129,168)

vars = {}
vars.CurePotency = {[1]=87, [2]=199, [3]=438, [4]=816, [5]=1056, [6]=1311}
cnums = {['Cure'] = 1, ['Cure II'] = 2, ['Cure III'] = 3, ['Cure IV'] = 4, ['Cure V'] = 5, ['Cure VI'] = 6}
ncures = {'Cure','Cure II','Cure III','Cure IV','Cure V','Cure VI'}

windower.register_event('addon command', function (command,...)
    command = command and command:lower() or 'help'
    local args = {...}
	
	if command == 'reload' then
		windower.send_command('lua unload healBot; lua load healBot')
	elseif command == 'unload' then
		windower.send_command('lua unload healBot')
	elseif S{'start','on'}:contains(command) then
		activate()
	elseif S{'stop','end','off'}:contains(command) then
		active = false
		printStatus()
	elseif command == 'status' then
		printStatus()
	elseif command == 'info' then
		printInfo()
	else
		windower.add_to_chat(0, 'Error: Unknown command')
	end
end)

function activate()
	local player = windower.ffxi.get_player()
	if player ~= nil then
		active = true
		if player.main_job == "RDM" then		maxCureTier = 4
		elseif player.main_job == "SCH" then	maxCureTier = 5
		elseif player.main_job == "WHM" then	maxCureTier = 6
		else
			active = false
		end
	end
	printStatus()
end

windower.register_event('load', function()
	lastAction = os.clock()
end)

windower.register_event('prerender', function()
	if active then
		local now = os.clock()
		if (now - lastAction) >= actionDelay then
			actionDelay = 0.5
			local player = windower.ffxi.get_player()
			local hpTable = getMissingHps()
			local curee = getMemberWithMostHpMissing(hpTable)
			if (player ~= nil) and (curee ~= nil) then
				local ncnum = get_tier_for_hp(curee.missing)
				if ncnum >= 3 then
					local spell = res.spells:with('en', ncures[ncnum])
					if (windower.ffxi.get_spell_recasts()[spell.recast_id] == 0) then
						windower.add_to_chat(0, "HealBot: "..spell.en.." "..rarr.." "..curee.name.."("..curee.missing..")")
						if (player.vitals.mp >= spell.mp_cost) then
							windower.send_command('input '..spell.prefix..' "'..spell.en..'" '..curee.name)
							actionDelay = spell.cast_time
						end
					else
						actionDelay = 0.3
					end
				end
			end
			lastAction = now
		end
	end
end)

function getMemberWithMostHpMissing(party)
	local curee = {['missing']=0}
	for n,p in pairs(party) do
		if (p.missing > curee.missing) and (p.hpp < 95) then
			curee.name = n
			curee.missing = p.missing
		end
	end
	if curee.missing > 0 then
		return curee
	else
		return nil
	end
end

--Returns a table with party members and how much hp they are missing
function getMissingHps()
	local pt = windower.ffxi.get_party()
	local pty = {pt.p0, pt.p1, pt.p2, pt.p3, pt.p4, pt.p5}
	local party = {}
	for _,player in pairs(pty) do
		if player ~= nil then
			local hpMissing = math.ceil((player.hp/(player.hpp/100)) - player.hp)
			party[player.name] = {['missing']=hpMissing, ['hpp']=player.hpp}
		end
	end
	return party
end

function get_tier_for_hp(hpMissing)
	local ncnum = maxCureTier
	local potency = vars.CurePotency[ncnum]
	if hpMissing < potency then
		local pdelta = potency - vars.CurePotency[ncnum-1]
		local threshold = potency - (pdelta * 0.5)
		while hpMissing < threshold do
			ncnum = ncnum - 1
			if ncnum > 1 then
				potency = vars.CurePotency[ncnum]
				pdelta = potency - vars.CurePotency[ncnum-1]
				threshold = potency - (pdelta * 0.5)
			else
				threshold = 0
			end
		end
	end
	return ncnum
end

function printInfo()
	windower.add_to_chat(0, 'healBot comands: (to be implemented)')
end

function printStatus()
	windower.add_to_chat(0, 'healBot: '..(active and 'active' or 'off'))
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