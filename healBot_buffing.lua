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
	['slow'] = 'Erase',				['STR Down'] = 'Erase',			['VIT Down'] = 'Erase',				['weight'] = 'Erase'
}

removal_map = {
	['Blindna']={'blindness'},		['Cursna']={'curse','doom'},	['Paralyna']={'paralysis'},			['Poisona']={'poison'},
	['Silena']={'silence'},			['Stona']={'petrification'},	['Viruna']={'disease','plague'},
	['Erase']={'weight','Accuracy Down','addle','AGI Down','Attack Down','bind','Bio','Burn','Choke','CHR Down','Defense Down','DEX Down','Dia','Drown','Elegy','Evasion Down','Frost','Inhibit TP','INT Down','Magic Acc. Down','Magic Atk. Down','Magic Def. Down','Magic Evasion Down','Max HP Down','Max MP Down','Max TP Down','MND Down','Nocturne','Rasp','Requiem','Shock','slow','STR Down','VIT Down'}
}

function checkOwnBuffs()
	local player = windower.ffxi.get_player()
	local activeBuffIds = player.buffs
	for _,id in pairs(activeBuffIds) do
		if (enfeebling:contains(id)) then
			registerDebuff(player.name, res.buffs[id].en, true)
		else
			registerBuff(player.name, res.buffs[id].en, true)
		end
	end
end

function checkOwnBuff(buffName)
	local player = windower.ffxi.get_player()
	local activeBuffIds = S(player.buffs)
	local buff = res.buffs:with('en', buffName)
	if (activeBuffIds:contains(buff.id)) then
		registerBuff(player.name, buffName, true)
	end
end

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