function checkBuffs(player, buffList)
	local now = os.clock()
	for targ, buffs in pairs(buffList) do
		if not isTooFar(targ) then
			for buff, info in pairs(buffs) do
				local spell = info.spell
				if (info.last == nil) or ((now - info.last) >= spell.duration) then
					if (windower.ffxi.get_spell_recasts()[spell.recast_id] == 0) and (player.vitals.mp >= spell.mp_cost) then
						windower.add_to_chat(0, "HealBot: "..spell.en.." "..rarr.." "..targ)
						windower.send_command('input '..spell.prefix..' "'..spell.en..'" '..targ)
						info.last = now		--TODO: Make sure it gets cast
						actionDelay = spell.cast_time
						return true
					end
				end
			end
		end
	end
	return false
end