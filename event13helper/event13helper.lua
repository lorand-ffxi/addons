_addon.name = 'event13helper'
_addon.author = 'Lorand'
_addon.command = 'e13h'
_addon.version = '0.1'

require('luau')

local last = os.clock()

--TODO: Add dagger
local props = {
	gaxe = {
		['Shield Break'] = 'Impaction',			['Iron Tempest'] = 'Scission',			['Sturmwind'] = 'Reverberation / Scission',
		['Armor Break'] = 'Impaction',			['Keen Edge'] = 'Compression',			['Weapon Break'] = 'Impaction',
		['Raging Rush'] = 'Induration / Reverberation',	['Full Break'] = 'Distortion',			['Steel Cyclone'] = 'Distortion / Detonation',
		['Metatron Torment'] = 'Light / Fusion',	["King's Justice"] = 'Fragmentation / Scission',['Fell Cleave'] = 'Scission / Detonation',
		["Ukko's Fury"] = 'Light / Fragmentation',	['Upheaval'] = 'Fusion / Compression'
	},
	pole = {
		['Double Thrust'] = 'Transfixion',		['Thunder Thrust'] = 'Transfixion / Impaction',	['Raiden Thrust'] = 'Transfixion / Impaction',
		['Leg Sweep'] = 'Impaction',			['Penta Thrust'] = 'Compression',		['Vorpal Thrust'] = 'Reverberation / Transfixion',
		['Skewer'] = 'Transfixion / Impaction',		['Wheeling Thrust'] = 'Fusion',			['Impulse Drive'] = 'Gravitation / Induration',
		['Geirskogul'] = 'Light / Distortion',		['Drakesbane'] = 'Fusion / Transfixion',	['Sonic Thrust'] = 'Transfixion / Scission',
		["Camlann's Torment"] = 'Light / Fragmentation',['Stardiver'] = 'Gravitation / Transfixion'
	},
	club = {
		['Shining Strike'] = 'Impaction',		['Seraph Strike'] = 'Impaction',		['Brainshaker'] = 'Reverberation',
		['Skullbreaker'] = 'Induration / Reverberation',['True Strike'] = 'Detonation / Impaction',	['Judgment'] = 'Impaction',
		['Hexa Strike'] = 'Fusion',			['Black Halo'] = 'Fragmentation / Compression',	['Randgrith'] = 'Light / Fragmentation',
		['Flash Nova'] = 'Induration / Reverberation',	['Realmrazer'] = 'Fusion / Impaction',
	},
	sword = {
		['Fast Blade'] = 'Scission',			['Burning Blade'] = 'Liquefaction',		['Red Lotus Blade'] = 'Liquefaction / Detonation',
		['Flat Blade'] = 'Impaction',			['Shining Blade'] = 'Scission',			['Seraph Blade'] = 'Scission',
		['Circle Blade'] = 'Reverberation / Impaction',	['Vorpal Blade'] = 'Scission / Impaction',	['Swift Blade'] = 'Gravitation',
		['Savage Blade'] = 'Fragmentation / Scission',	['Knights of Round'] = 'Light / Fusion',	['Death Blossom'] = 'Fragmentation / Distortion',
		['Atonement'] = 'Fusion / Reverberation',	['Expiacion'] = 'Distortion / Scission',	['Chant du Cygne'] = 'Light / Distortion',
		['Requiescat'] = 'Gravitation / Scission'
	}
}

local need_next = {
	Transfixion = {'Compression','Scission','Reverberation'},	Compression = {'Transfixion','Detonation'},
	Liquefaction = {'Scission','Impaction'},			Scission = {'Liquefaction','Reverberation','Detonation'},
	Reverberation = {'Induration','Impaction'},			Detonation = {'Compression','Scission'},
	Induration = {'Compression','Reverberation','Impaction'},	Impaction = {'Liquefaction','Detonation'},
	Fusion = {'Gravitation','Fragmentation'},			Fragmentation = {'Distortion','Fusion'},
	Distortion = {'Fusion','Gravitation'},				Gravitation = {'Fragmentation','Distortion'},
	Light = {'Light'},						Darkness = {'Darkness'}
}

windower.register_event('incoming text',function (original)
	local now = os.clock()
	if (now - last) > 2 then
		if original:contains('Skillchain Level') then
			local words = original:split(' ')
			local sc = words[4]
			sc = sc:sub(1, #sc-2)
			
			atc('Saw skillchain: '..sc)
			
			local need = need_next[sc]
			local want = {}
			
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
			
			for k,v in pairs(want) do
				atc(tostring(k)..': '..tostring(v))
			end
		end
		last = now
	end
end)

function atc(c, msg)
	if (type(c) == 'string') and (msg == nil) then
		msg = c
		c = 0
	end
	windower.add_to_chat(c, msg)
end