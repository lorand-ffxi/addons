buffList = {}
debuffList = {}

function get_active_buffs()
	local activeBuffs = S{}
	local player = windower.ffxi.get_player()
	if (player ~= nil) then
		for _,bid in pairs(player.buffs) do
			local bname = res.buffs[bid]
			activeBuffs[bid] = bname
			activeBuffs[bname] = bid
		end
	end
	return activeBuffs
end

function buffActive(...)
	local args = {...}
	local activeBuffs = get_active_buffs()
	for _,buff in pairs(args) do
		if activeBuffs:contains(buff) then
			return true
		end
	end
	return false
end

function checkOwnBuffs()
	local player = windower.ffxi.get_player()
	--Iterate through actually active buffs to register their presence
	local activeBuffIds = player.buffs
	for _,id in pairs(activeBuffIds) do
		if (enfeebling:contains(id)) then
			registerDebuff(player.name, res.buffs[id].en, true)
		else
			registerBuff(player.name, res.buffs[id].en, true)
		end
	end
	--Iterate through buffs that should be active to make sure they are
	--local myBuffs = buffList[player.name]
	--if (myBuffs ~= nil) then
	--	local activeBuffs = get_active_buffs()
	--	for buff,info in pairs(myBuffs) do
	--		if activeBuffs:contains(buff) then
				--registerBuff(player.name, buff, true)
	--		else
	--			registerBuff(player.name, buff, false)
	--		end
	--	end
	--end
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
							info.attempted = now
							return {action = spell, targetName = targ}
						end
					end
				end
			end
		end
	end
	return nil
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
							info.attempted = now
							return {action = spell, targetName = targ, msg = ' ('..debuff..')'}
						end
					end
				else
					debuffList[targ][debuff] = nil
				end
			end
		end
	end
	return nil
end

function registerNewBuff(args, use)
	local me = windower.ffxi.get_player()
	local targetName = args[1] and args[1] or ''
	local spellA = args[2] and args[2] or ''
	local spellB = args[3] and ' '..args[3] or ''
	local spellC = args[4] and ' '..args[4] or ''
	local spellName = formatSpellName(spellA..spellB..spellC)
	
	if spellName == nil then
		atc('Error: Unable to parse spell name')
		return
	end
	
	local target = windower.ffxi.get_mob_by_name(targetName)
	if target == nil then
		if (targetName == '<t>') then
			target = windower.ffxi.get_mob_by_target()
		elseif S{'<me>','me'}:contains(targetName) then
			target = windower.ffxi.get_mob_by_id(me.id)
		end
		if target == nil then		
			atc('Invalid buff target: '..targetName)
			return
		end
	end
	
	local spell = res.spells:with('en', spellName)
	if spell == nil then
		atc('Invalid spell name: '..spellName)
		return
	end
	if not canCast(spell) then
		atc('Unable to cast spell: '..spellName)
		return
	end
	
	local targetType = 'None'
	if (target.in_alliance) then
		if (target.in_party) then
			if (me.name == target.name) then
				targetType = 'Self'
			else
				targetType = 'Party'
			end
		else
			targetType = 'Ally'
		end
	end
	local validTargets = S(spell.targets)
	if (not validTargets:contains(targetType)) then
		atc(target.name..' is an invalid target for '..spell.en..' (Type: '..targetType..')')
		return
	end
	
	local monitoring = getMonitoredPlayers()
	if (not monitoring[target.name]) then
		monitorCommand('watch', target.name)
	end
	
	if buffList[target.name] == nil then
		buffList[target.name] = {}
	end
	local bname = getBuffForSpell(spell.en)
	if (use) then
		buffList[target.name][bname] = {['spell']=spell, ['maintain']=true}
		atc('Will maintain buff: '..spell.en..' '..rarr..' '..target.name)
		if (targetType == 'Self') then
			checkOwnBuff(bname)
		end
	else
		buffList[target.name][bname] = nil
		atc('Will no longer maintain buff: '..spell.en..' '..rarr..' '..target.name)
	end
end

function getBuffForSpell(spellName)
	if (buff_map[spellName] ~= nil) then
		return buff_map[spellName]
	else
		local buffName = spellName
		local spLoc = spellName:find(' ')
		if (spLoc ~= nil) then
			buffName = spellName:sub(1, spLoc-1)
		end
		return buffName
	end
end

function registerDebuff(targetName, debuffName, gain)
	if debuffList[targetName] == nil then
		debuffList[targetName] = {}
	end
	if (debuffName == 'slow') then
		registerBuff(targetName, 'Haste', false)
	end
	
	if gain then
		local ignoreList = ignoreDebuffs[debuffName]
		local pmInfo = partyMemberInfo[targetName]
		if (ignoreList ~= nil) and (pmInfo ~= nil) then
			if ignoreList:contains(pmInfo.job) and ignoreList:contains(pmInfo.subjob) then
				atc('Ignoring '..debuffName..' on '..targetName..' because of their job')
				return
			end
		end
		
		debuffList[targetName][debuffName] = {['landed']=os.clock()}
		atcd('Detected debuff: '..debuffName..' '..rarr..' '..targetName)	
	else
		debuffList[targetName][debuffName] = nil
		atcd('Detected debuff: '..debuffName..' wore off '..targetName)
	end
end

function registerBuff(targetName, buffName, gain)
	if buffList[targetName] == nil then
		buffList[targetName] = {}
	end
	if buffList[targetName][buffName] ~= nil then
		if gain then
			buffList[targetName][buffName]['landed'] = os.clock()
			atcd("Detected buff: "..buffName.." "..rarr.." "..targetName)
		else
			buffList[targetName][buffName]['landed'] = nil
			atcd("Detected buff: "..buffName.." wore off "..targetName)
		end
	end
end

function resetDebuffTimers(player)
	debuffList[player] = {}
end

function resetBuffTimers(player)
	if buffList[player] == nil then return end
	for buffName,_ in pairs(buffList[player]) do
		buffList[player][buffName]['landed'] = nil
	end
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