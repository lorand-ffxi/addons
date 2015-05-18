_addon.name = 'event13helper'
_addon.author = 'Lorand'
_addon.command = 'e13h'
_addon.version = '0.2'

require('luau')

local last = os.clock()
local last_scs = S{}
local last_weap_type = 'unknown'

local props = {
	gaxe = {
		['Shield Break'] = S{'Impaction'},			['Iron Tempest'] = S{'Scission'},			['Sturmwind'] = S{'Reverberation', 'Scission'},
		['Armor Break'] = S{'Impaction'},			['Keen Edge'] = S{'Compression'},			['Weapon Break'] = S{'Impaction'},
		['Raging Rush'] = S{'Induration', 'Reverberation'},	['Full Break'] = S{'Distortion'},			['Steel Cyclone'] = S{'Distortion', 'Detonation'},
		['Metatron Torment'] = S{'Light', 'Fusion'},		["King's Justice"] = S{'Fragmentation', 'Scission'},	['Fell Cleave'] = S{'Scission', 'Detonation'},
		["Ukko's Fury"] = S{'Light', 'Fragmentation'},		['Upheaval'] = S{'Fusion', 'Compression'}
	},
	pole = {
		['Double Thrust'] = S{'Transfixion'},			['Thunder Thrust'] = S{'Transfixion', 'Impaction'},	['Raiden Thrust'] = S{'Transfixion', 'Impaction'},
		['Leg Sweep'] = S{'Impaction'},				['Penta Thrust'] = S{'Compression'},			['Vorpal Thrust'] = S{'Reverberation', 'Transfixion'},
		['Skewer'] = S{'Transfixion', 'Impaction'},		['Wheeling Thrust'] = S{'Fusion'},			['Impulse Drive'] = S{'Gravitation', 'Induration'},
		['Geirskogul'] = S{'Light', 'Distortion'},		['Drakesbane'] = S{'Fusion', 'Transfixion'},		['Sonic Thrust'] = S{'Transfixion', 'Scission'},
		["Camlann's Torment"] = S{'Light', 'Fragmentation'},	['Stardiver'] = S{'Gravitation', 'Transfixion'}
	},
	club = {
		['Shining Strike'] = S{'Impaction'},			['Seraph Strike'] = S{'Impaction'},			['Brainshaker'] = S{'Reverberation'},
		['Skullbreaker'] = S{'Induration', 'Reverberation'},	['True Strike'] = S{'Detonation', 'Impaction'},		['Judgment'] = S{'Impaction'},
		['Hexa Strike'] = S{'Fusion'},				['Black Halo'] = S{'Fragmentation', 'Compression'},	['Randgrith'] = S{'Light', 'Fragmentation'},
		['Flash Nova'] = S{'Induration', 'Reverberation'},	['Realmrazer'] = S{'Fusion', 'Impaction'}
	},
	sword = {
		['Fast Blade'] = S{'Scission'},				['Burning Blade'] = S{'Liquefaction'},			['Red Lotus Blade'] = S{'Liquefaction', 'Detonation'},
		['Flat Blade'] = S{'Impaction'},			['Shining Blade'] = S{'Scission'},			['Seraph Blade'] = S{'Scission'},
		['Circle Blade'] = S{'Reverberation', 'Impaction'},	['Vorpal Blade'] = S{'Scission', 'Impaction'},		['Swift Blade'] = S{'Gravitation'},
		['Savage Blade'] = S{'Fragmentation', 'Scission'},	['Knights of Round'] = S{'Light', 'Fusion'},		['Death Blossom'] = S{'Fragmentation', 'Distortion'},
		['Atonement'] = S{'Fusion', 'Reverberation'},		['Expiacion'] = S{'Distortion', 'Scission'},		['Chant du Cygne'] = S{'Light', 'Distortion'},
		['Requiescat'] = S{'Gravitation', 'Scission'}
	},
	dagger = {
		['Wasp Sting'] = S{'Scission'},				['Viper Bite'] = S{'Scission'},				['Shadowstitch'] = S{'Reverberation'},
		['Gust Slash'] = S{'Detonation'},			['Cyclone'] = S{'Detonation', 'Impaction'},		['Dancing Edge'] = S{'Scission', 'Detonation'},
		['Shark Bite'] = S{'Fragmentation'},			['Evisceration'] = S{'Gravitation', 'Transfixion'},	['Mercy Stroke'] = S{'Darkness', 'Gravitation'},
		['Mandalic Stab'] = S{'Fusion', 'Compression'},		['Mordant Rime'] = S{'Fragmentation', 'Distortion'},	['Pyrrhic Kleos'] = S{'Distortion', 'Scission'},	
		['Aeolian Edge'] = S{'Impaction', 'Scission', 'Detonation'},["Rudra's Storm"] = S{'Darkness', 'Distortion'},	['Exenterator'] = S{'Fragmentation', 'Scission'},
	},
	gob = {
		['Bomb Toss'] = S{'Liquefaction'},
		['Goblin Rush'] = S{'Fusion', 'Impaction'},
	}
}

local function next_weap(last_weap)
	if last_weap == 'gaxe' then		return 'pole'
	elseif last_weap == 'pole' then		return 'club'
	elseif last_weap == 'club' then		return 'sword'
	elseif last_weap == 'sword' then	return 'dagger'
	elseif last_weap == 'dagger' then	return 'gob'
	elseif last_weap == 'gob' then		return 'gaxe'
	end
end

local need_next = {
	Transfixion = {'Compression','Scission','Reverberation'},	Compression = {'Transfixion','Detonation'},
	Liquefaction = {'Scission','Impaction'},			Scission = {'Liquefaction','Reverberation','Detonation'},
	Reverberation = {'Induration','Impaction'},			Detonation = {'Compression','Scission'},
	Induration = {'Compression','Reverberation','Impaction'},	Impaction = {'Liquefaction','Detonation'},
	Fusion = {'Gravitation','Fragmentation'},			Fragmentation = {'Distortion','Fusion'},
	Distortion = {'Fusion','Gravitation'},				Gravitation = {'Fragmentation','Distortion'},
	Light = {'Light','Transfixion','Liquefaction','Detonation','Impaction','Fusion','Fragmentation'},
	Darkness = {'Darkness','Compression','Induration','Scission','Reverberation','Distortion','Gravitation'}
}

windower.register_event('incoming text',function (original)
	local caught = 0
	if original:contains('Accomplished Adventurer uses') then
		caught = 32
	elseif original:contains('Rolandienne uses') then
		caught = 20
	elseif original:contains('Urbiolaine uses') then
		caught = 19
	elseif original:contains('Fablinix uses') then
		caught = 17
	end

	local used = ''
	if caught > 0 then
		used = original:sub(caught, #original-1)
		for wtype,wses in pairs(props) do
			if wses[used] then
				last_weap_type = wtype
			end
		end
	end
	
	local now = os.clock()
	local used_props = S{}
	
	if original:contains('Skillchain Level') and ((now - last) > 2) then
		local words = original:split(' ')
		local sc = words[4]
		sc = sc:sub(1, #sc-2)
		used_props:add(sc)
		last = now
	elseif original:contains('Accomplished Adventurer uses') and (last_weap_type == 'gaxe') then
		local wsprops = props.gaxe[used]
		if wsprops then
			used_props = wsprops
		end
	elseif original:contains('Good Call') then
		last_weap_type = next_weap(last_weap_type)
		used_props = last_scs
	elseif original:contains('Bad call!') then
		last_weap_type = next_weap(last_weap_type)
		local wsprops = props[last_weap_type][used]
		if wsprops then
			used_props = wsprops
		end
	end
	
	if not used_props:empty() then
		last_scs = used_props
		local want = {}
		for wsprop,_ in pairs(used_props) do
			local need = need_next[wsprop]
			for _,prop in pairs(need) do
				for weap,wses in pairs(props) do
					for ws,ps in pairs(wses) do
						for _,p in pairs(need) do
							if ps:contains(p) then
								if not want[weap] then
									want[weap] = S{}
								end
								want[weap]:add(ws)
							end
						end
					end
				end
			end
			
		end
		
		local w = next_weap(last_weap_type)
		atc(215, tostring(want[w]))
	end
end)

function atc(c, msg)
	if (type(c) == 'string') and (msg == nil) then
		msg = c
		c = 0
	end
	windower.add_to_chat(c, msg)
end