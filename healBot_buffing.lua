local debuff_map = {
	['Accuracy Down'] = 'Erase',	['addle'] = 'Erase',			['AGI Down'] = 'Erase',				['Attack Down'] = 'Erase',
	['bind'] = 'Erase',				['Bio'] = 'Erase',				['blindness'] = 'Blindna',			['Burn'] = 'Erase',
	['Choke'] = 'Erase',			['CHR Down'] = 'Erase',			['curse'] = 'Cursna',				['Defense Down'] = 'Erase',
	['DEX Down'] = 'Erase',			['Dia'] = 'Erase',				['disease'] = 'Viruna',				['doom'] = 'Cursna',
	['Drown'] = 'Erase',			['Elegy'] = 'Erase',			['Evasion Down'] = 'Erase',			['Frost'] = 'Erase',
	['Inhibit TP'] = 'Erase',		['INT Down'] = 'Erase',			['Lullaby'] = 'Cure',				['Magic Acc. Down'] = 'Erase',
	['Magic Atk. Down'] = 'Erase',	['Magic Def. Down'] = 'Erase',	['Magic Evasion Down'] = 'Erase',	['Max HP Down'] = 'Erase',
	['Max MP Down'] = 'Erase',		['Max TP Down'] = 'Erase',		['MND Down'] = 'Erase',				['Nocturne'] = 'Erase',
	['paralysis'] = 'Paralyna',		['petrification'] = 'Stona',	['plague'] = 'Viruna',				['poison'] = 'Poisona',
	['Rasp'] = 'Erase',				['Requiem'] = 'Erase',			['Shock'] = 'Erase',				['silence'] = 'Silena',
	--['sleep'] = 'Cure',				
	['slow'] = 'Erase',				['STR Down'] = 'Erase',				['VIT Down'] = 'Erase',			['weight'] = 'Erase'
}

function checkBuffs(player, buffList)
	local now = os.clock()
	for targ, buffs in pairs(buffList) do
		if not isTooFar(targ) then
			for buff, info in pairs(buffs) do
				local spell = info.spell
				if (info.landed == nil) then
					if (info.attempted == nil) or ((now - info.attempted) >= 3) then
						if (windower.ffxi.get_spell_recasts()[spell.recast_id] == 0) and (player.vitals.mp >= spell.mp_cost) then
							windower.add_to_chat(0, "HealBot: "..spell.en.." "..rarr.." "..targ)
							windower.send_command('input '..spell.prefix..' "'..spell.en..'" '..targ)
							info.attempted = now
							actionDelay = spell.cast_time
							return true
						end
					end
				end
			end
		end
	end
	return false
end

function checkDebuffs(player, debuffList)
	local now = os.clock()
	for targ, debuffs in pairs(debuffList) do
		if not isTooFar(targ) then
			for debuff, info in pairs(debuffs) do
				local removalSpellName = debuff_map[debuff]
				if removalSpellName ~= nil then
					if (info.attempted == nil) or ((now - info.attempted) >= 3) then
						local spell = res.spells:with('en', removalSpellName)
						if (windower.ffxi.get_spell_recasts()[spell.recast_id] == 0) and (player.vitals.mp >= spell.mp_cost) then
							windower.add_to_chat(0, "HealBot: "..spell.en.." "..rarr.." "..targ)
							windower.send_command('input '..spell.prefix..' "'..spell.en..'" '..targ)
							info.attempted = now
							actionDelay = spell.cast_time
							return true
						end
					end
				else
					debuffList[targ][debuff] = nil
				end
			end
		end
	end
	return false
end