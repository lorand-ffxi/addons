minCureTier = 3
potencies = {[1]=87, [2]=199, [3]=438, [4]=816, [5]=1056, [6]=1311}
cnums = {['Cure'] = 1, ['Cure II'] = 2, ['Cure III'] = 3, ['Cure IV'] = 4, ['Cure V'] = 5, ['Cure VI'] = 6}
ncures = {'Cure','Cure II','Cure III','Cure IV','Cure V','Cure VI'}
npcs = S{'Joachim', 'Ulmia', 'Cherukiki'}

function cureSomeone(player)
	local hpTable = getMissingHps()
	local curee = getMemberWithMostHpMissing(hpTable)
	if (curee ~= nil) and (not isTooFar(curee.name)) then
		local ncnum = get_tier_for_hp(curee.missing)
		if ncnum >= minCureTier then
			local spell = res.spells:with('en', ncures[ncnum])
			if (windower.ffxi.get_spell_recasts()[spell.recast_id] == 0) then
				if (player.vitals.mp >= spell.mp_cost) then
					windower.add_to_chat(0, "HealBot: "..spell.en.." "..rarr.." "..curee.name.."("..curee.missing..")")
					windower.send_command('input '..spell.prefix..' "'..spell.en..'" '..curee.name)
					actionDelay = spell.cast_time
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
	windower.add_to_chat(0, highestTier)
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
		if (p.missing > curee.missing) and (p.hpp < 95) and (not npcs:contains(n)) then
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