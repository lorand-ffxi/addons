function cureSomeone(player)
	local hpTable = getMissingHps()
	local curee = getMemberWithMostHpMissing(hpTable)
	if (curee ~= nil) and (not isTooFar(curee.name)) then
		local ncnum = get_tier_for_hp(curee.missing)
		if ncnum >= minCureTier then
			local spell = res.spells:with('en', ncures[ncnum])
			if (windower.ffxi.get_spell_recasts()[spell.recast_id] == 0) then
				if (player.vitals.mp >= spell.mp_cost) then
					atcd(spell.en..' '..rarr..' '..curee.name..'('..curee.missing..')')
					windower.send_command('input '..spell.prefix..' "'..spell.en..'" '..curee.name)
					actionDelay = 0.5
					--actionDelay = spell.cast_time
					return true
				end
			end
		end
	end
	return false
end

function determineHighestCureTier()
	local highestTier = 0
	for id, avail in pairs(windower.ffxi.get_spells()) do
		if avail then
			local spell = res.spells[id]
			if S(ncures):contains(spell.en) then
				if canCast(spell) then
					local tier = cnums[spell.en]
					if tier > highestTier then
						highestTier = tier
					end
				end				
			end
		end
	end
	return highestTier
end

function get_tier_for_hp(hpMissing)
	local ncnum = maxCureTier
	local potency = potencies[ncnum]
	if hpMissing < potency then
		local pdelta = potency - potencies[ncnum-1]
		local threshold = potency - (pdelta * 0.5)
		while hpMissing < threshold do
			ncnum = ncnum - 1
			if ncnum > 1 then
				potency = potencies[ncnum]
				pdelta = potency - potencies[ncnum-1]
				threshold = potency - (pdelta * 0.5)
			else
				threshold = 0
			end
		end
	end
	return ncnum
end

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
	local targets = getMonitoredPlayers()
	local hpTable = {}
	for _,target in pairs(targets) do
		local hpMissing = 0
		if (target.hp ~= nil) then
			hpMissing = math.ceil((target.hp/(target.hpp/100))-target.hp)
		else
			hpMissing = 1500 - math.ceil((target.hpp/100)*1500)	--temporary fix for out of party characters
		end
		hpTable[target.name] = {['missing']=hpMissing, ['hpp']=target.hpp}
		if target.hpp == 0 then
			resetBuffTimers(target.name)
			resetDebuffTimers(target.name)
		end
	end
	return hpTable
end

-----------------------------------------------------------------------------------------------------------
--[[
Copyright © 2015, Lorand
All rights reserved.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of healBot nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Lorand BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]
-----------------------------------------------------------------------------------------------------------