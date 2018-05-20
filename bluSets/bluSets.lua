_addon.name = 'BLUSets'
_addon.version = '1.3.1'
_addon.author = 'Lorand / Nitrous (Shiva)'
_addon.commands = {'blusets','bs','blu'}
_addon.lastUpdate = '2016.11.05.3'

require('lor/lor_utils')
_libs.lor.req('chat', 'tables', {n='settings',v='2016.10.23.1'})
_libs.req('tables', 'strings', 'logger', 'sets')
local res = require('resources')
local chat = require('chat')

local spell_lists = {
    useless = {"Pollen","Footkick","Sprout Smack","Wild Oats","Power Attack","Metallic Body","Queasyshroom","Battle Dance","Feather Storm","Head Butt","Healing Breeze","Helldive","Blastbomb","Bludgeon","Blood Drain","Claw Cyclone","Poison Breath","Soporific","Screwdriver","Bomb Toss","Grand Slam","Wild Carrotchan","Caotic Eye","Smite of Rage","Digest","Pinecone Bomb","Jet Stream","Uppercut","Terror Touch","MP Drainkiss","Venom Shell","Stinking Gas","Mandibular Bite","Awful Eye","Blood Saber","Refueling","Self-Destruct","Feather Barrier","Flying Hip Press","Spiral Spin","Death Scissors","Seedspray","1000 Needles","Body Slam","Hydro Shot","Frypan","Spinal Cleave","Voracious Trunk","Enervation","Warm-Up","Hysteric Barrage","Cannonball","Sub-zero Smash","Ram Charge","Mind Blast","Plasma Charge","Vertical Cleave","Plenilune Embrace","Demoralizing Roar","Final Sting","Osmosis","Vapor Spray","Thunder Breath","Atra. Libation"},
    need = {"Cocoon","Sickle Slash","Blank Gaze","Tail Slap","Magic Fruit","Acrid Stream","Yawn","Saline Coat","Magic Hammer","Regeneration","Fantod","Battery Charge","Empty Thrash","Magic Barrier","Delta Thrust","Whirl of Rage","Dream Flower","Heavy Strike","Occultation","Barbed Crescent","Winds of Promy.","Thrashing Assault","Barrier Tusk","Diffusion Ray","White Wind","Molting Plumage","Sudden Lunge","Nat. Meditation","Glutinous Dart","Paralyzing Triad","Retinal Glare","Carcharian Verve","Erratic Flutter","Subduction","Sinker Drill","Sweeping Gouge","Searing Tempest","Blinding Fulgor","Spectral Floe","Scouring Spate","Anvil Lightning","Silent Storm","Entomb","Tenebral Crush","Mighty Guard"},
    nice = {"Animating Wail","Quad. Continuum","Blazing Bound","Mortal Ray","Sheep Song","Battle Dance","MP Drainkiss","Sound Blast","Frightful Roar","Uppercut","Memento Mori","Frenetic Rip","Infrasonics","Spinal Cleave","Zephyr Mantle","Disseverment","Diamondhide","Goblin Rush","Amplification","Vanity Dive","Temporal Shift","Evryone. Grudge","Actinic Burst","Quadrastrike","Benthic Typhoon","Thermal Pulse","Palling Salvo","Reaving Wind","Thunderbolt","Embalming Earth","Restoral","Saurian Slide","Plenilune Embrace","Amorphic Spikes","Water Bomb","Regurgitation","Charged Whisker","Rail Cannon"},
    vw = {"Firespit","Heat Breath","Thermal Pulse","Blastbomb","Sandspin","Magnetite Cloud","Cimicine Discharge","Bad Breath","Acrid Stream","Maelstrom","Corrosive Ooze","Cursed Sphere","Hecatomb Wave","Mysterious Light","Leafstorm","Reaving Wind","Infrasonics","Ice Break","Cold Wave","Frost Breath","Temporal Shift","Mind Blast","Charged Whisker","Blitzstrahl","Actinic Burst","Radiant Breath","Blank Gaze","Light of Penance","Death Ray","Eyes on Me","Sandspray"}
}


defaults = {
    setmode = 'PreserveTraits',
    setspeed = 0.65,
    spellsets = {
        default = T{},
        vw1 = T{
            slot01='Firespit', slot02='Heat Breath', slot03='Thermal Pulse', slot04='Blastbomb', slot05='Infrasonics', slot06='Frost Breath',
            slot07='Ice Break', slot08='Cold Wave', slot09='Sandspin', slot10='Magnetite Cloud', slot11='Cimicine Discharge',
            slot12='Bad Breath', slot13='Acrid Stream', slot14='Maelstrom', slot15='Corrosive Ooze', slot16='Cursed Sphere', slot17='Awful Eye'
        },
        vw2 = T{
            slot01='Hecatomb Wave', slot02='Mysterious Light', slot03='Leafstorm', slot04='Reaving Wind', slot05='Temporal Shift', slot06='Mind Blast',
            slot07='Blitzstrahl', slot08='Charged Whisker', slot09='Blank Gaze', slot10='Radiant Breath', slot11='Light of Penance', slot12='Actinic Burst',
            slot13='Death Ray', slot14='Eyes On Me', slot15='Sandspray'
        }
    }
}
settings = _libs.lor.settings.load('data/settings.lua', defaults)

local last_set_name = nil


windower.register_event('addon command', function(...)
    if windower.ffxi.get_player()['main_job_id'] ~= 16 then
        error('You are not on (main) Blue Mage.')
        return nil
    end
    local args = T{...}
    if args ~= nil then
        local cmd = table.remove(args,1):lower()
        if S{'reload','unload'}:contains(cmd) then
            windower.send_command(('lua %s %s'):format(cmd, _addon.name))
        elseif cmd == 'removeall' then
            remove_all_spells('trigger')
        elseif cmd == 'add' then
            if args[2] ~= nil then
                local slot = table.remove(args,1)
                local spell = args:sconcat()
                set_single_spell(spell:lower(),slot)
            end
        elseif cmd == 'convert' then
            _libs.lor.settings.convert_config('data/settings.xml', 'data/settings.lua')
            atc('For changes to take effect, please //blusets reload ')
        elseif cmd == 'save' then
            if args[1] ~= nil then
                save_set(args[1])
            end
        elseif cmd == 'diff' then
            if args[1] == nil then
                atc('Usage: //blusets diff set_name_1 [set_name_2]')
                return
            end
            local name1 = args[1]
            local set1 = settings.spellsets[args[1]]
            if set1 == nil then
                atcfs(123, 'Invalid set name: %s', args[1])
                return
            end
            local name2 = args[2] or get_current_set_name() or '[current]'
            local set2 = settings.spellsets[args[2]] or get_current_spellset()
            set1 = S(table.values(set1))
            set2 = S(table.values(set2))
            
            if set1 == set2 then
                atcfs('%s is identical to %s', name1, name2)
            else
                local set1_only = set1:diff(set2)
                if table.size(set1_only) > 0 then
                    atcfs('Only in %s: %s', name1, (', '):join(set1_only))
                end
                local set2_only = set2:diff(set1)
                if table.size(set2_only) > 0 then
                    atcfs('Only in %s: %s', name2, (', '):join(set2_only))
                end
                local in_both = set1:intersection(set2)
                if table.size(in_both) > 0 then
                    atcfs('In both %s and %s: %s', name1, name2, (', '):join(in_both))
                end
            end
            --atcfs('set1: %s', ', ':join(set1))
            --atcfs('set2: %s', ', ':join(set2))
        elseif S{'load', 'set'}:contains(cmd) then
            local set_name = get_current_set_name()
            if set_name == nil then
                last_set_name = last_set_name or 'unknown'
                local new_set_name = ('%s_%s'):format(last_set_name, os.date('%Y.%m.%d_%H.%M.%S'))
                save_set(new_set_name)
            end
            if args[1] ~= nil then
                set_spells(args[1], args[2] or settings.setmode)
                last_set_name = args[1]
            end
        elseif cmd == 'current' then
            local set_name = get_current_set_name() or '[unknown]'
            atcfs('Current spell set: %s', set_name)
            current_set:print()
        elseif cmd == 'list' then
            if args[1] ~= nil then
                if args[1] == 'sets' then
                    get_spellset_list()
                else
                    get_spellset_content(args[1])
                end
            else
                atc(123, 'Error: list requires an additional argument (sets or spells)')
            end
        elseif cmd == 'check' then
            local which = args[1]
            local check_spells = spell_lists[which]
            if (which == nil) or (check_spells == nil) then
                atcfs(123, 'Please specify a valid spell list to check (%s)', ('|'):join(table.keys(spell_lists)))
                return
            end
            local wf_spells = windower.ffxi.get_spells()
            local blu_have = S{}
            local blu_need = S{}
            for _, blu_spell in pairs(check_spells) do
                local spell_name = blu_spell:lower()
                for id,spell in pairs(res.spells) do
                    if spell.en:lower() == spell_name then
                        if wf_spells[id] then
                            blu_have:add(spell.en)
                        else
                            blu_need:add(spell.en)
                        end
                    end
                end
            end
            
            local prefix_map = {nice='Nice to have',need='Necessary'}
            local prefix = prefix_map[which] or which:ucfirst()
            atcfs('%s spells learned: %s', prefix, (', '):join(blu_have))
            atcfs('%s spells needed: %s', prefix, (', '):join(blu_need))
        elseif cmd == 'learned' then
            local wf_spells = windower.ffxi.get_spells()
            local spell_name = (' '):join(args):lower()
            for id,spell in pairs(res.spells) do
                if spell.en:lower() == spell_name then
                    atcfs('%s: %s', spell.en, wf_spells[id])
                    break
                end
            end
        elseif cmd == 'help' then
            local helptext = [[BLUSets - Command List:
            removeall - Unsets all spells.
            convert -- Converts settings.xml to settings.lua
            load <setname> [ClearFirst|PreserveTraits] -- Set (setname)'s spells,
                             optional parameter: ClearFirst or PreserveTraits: overrides
                             setting to clear spells first or remove individually,
                             preserving traits where possible. Default: use settings or
                             preservetraits if settings not configured.
            add <slot> <spell> -- Set (spell) to slot (slot (number)).
            save <setname> -- Saves current spellset as (setname).
            current -- Lists currently set spells.
            list {sets,<setname>} -- Lists available spell sets, or spells in the given set
            diff <setname1> [<setname2>] -- Compares setname1 to setname2 if provided, or your currently equipped spells
            check <listname> -- Checks your learned spells against lists published in guides here:
                              http://www.ffxiah.com/forum/topic/30626/the-beast-within-a-guide-to-blue-mage
                              https://www.bg-wiki.com/bg/Out_of_the_BLU#Spells_You_Should_Learn
            learned <spellname> -- Tells you whether or not you've learned the given spell
            help -- Shows this menu.]]
            for _, line in ipairs(helptext:split('\n')) do
                atcfs(207, '%s%s', line, chat.controls.reset)
            end
        end
    end
end)


function get_current_set_name()
    local current_set = get_current_spellset()
    local current_spells = S(table.values(current_set))
    for set_name, spell_set in pairs(settings.spellsets) do
        if table.equals(S(table.values(spell_set)), current_spells) then
            return set_name
        end
    end
    return nil
end


function initialize()
    spells = res.spells:type('BlueMagic')
    get_current_spellset()
end

windower.register_event('load', initialize:cond(function() return windower.ffxi.get_info().logged_in end))

windower.register_event('login', initialize)

windower.register_event('job change', initialize:cond(function(job) return job == 16 end))

function set_spells(spellset, setmode)
    if windower.ffxi.get_player()['main_job_id'] ~= 16 --[[and windower.ffxi.get_player()['sub_job_id'] ~= 16]] then
        error('Main job not set to Blue Mage.')
        return
    end
    if settings.spellsets[spellset] == nil then
        error('Set not defined: '..spellset)
        return
    end
    if is_spellset_equipped(settings.spellsets[spellset]) then
        log(spellset..' was already equipped.')
        return
    end

    log('Starting to set '..spellset..'.')
    if setmode:lower() == 'clearfirst' then
        remove_all_spells()
        set_spells_from_spellset:schedule(settings.setspeed, spellset, 'add')
    elseif setmode:lower() == 'preservetraits' then
        set_spells_from_spellset(spellset, 'remove')
    else
        error('Unexpected setmode: '..setmode)
    end
end

function is_spellset_equipped(spellset)
    return S(spellset):map(string.lower) == S(get_current_spellset())
end

function set_spells_from_spellset(spellset, setPhase)
    local setToSet = settings.spellsets[spellset]
    local currentSet = get_current_spellset()

    if setPhase == 'remove' then
        -- Remove Phase
        for k,v in pairs(currentSet) do
            if not setToSet:contains(v:lower()) then
                setSlot = k
                local slotToRemove = tonumber(k:sub(5, k:len()))

                windower.ffxi.remove_blue_magic_spell(slotToRemove)
                --log('Removed spell: '..v..' at #'..slotToRemove)
                set_spells_from_spellset:schedule(settings.setspeed, spellset, 'remove')
                return
            end
        end
    end
    -- Did not find spell to remove. Start set phase
    -- Find empty slot:
    local slotToSetTo
    for i = 1, 20 do
        local slotName = ('slot%02u'):format(i)
        if currentSet[slotName] == nil then
            slotToSetTo = i
            break
        end
    end

    if slotToSetTo ~= nil then
        -- We found an empty slot. Find a spell to set.
        for k,v in pairs(setToSet) do
            if not currentSet:contains(v:lower()) then
                if v ~= nil then
                    local spellID = find_spell_id_by_name(v)
                    if spellID ~= nil then
                        windower.ffxi.set_blue_magic_spell(spellID, tonumber(slotToSetTo))
                        --log('Set spell: '..v..' ('..spellID..') at: '..slotToSetTo)
                        set_spells_from_spellset:schedule(settings.setspeed, spellset, 'add')
                        return
                    end
                end
            end
        end
    end

    -- Unable to find any spells to set. Must be complete.
    log(spellset..' has been equipped.')
    windower.send_command('@timers c "Blue Magic Cooldown" 60 up')
end

function find_spell_id_by_name(spellname)
    for spell in spells:it() do
        if spell['english']:lower() == spellname:lower() then
            return spell['id']
        end
    end
    return nil
end

function set_single_spell(setspell,slot)
    if windower.ffxi.get_player()['main_job_id'] ~= 16 --[[and windower.ffxi.get_player()['sub_job_id'] ~= 16]] then return nil end

    local tmpTable = T(get_current_spellset())
    for key,val in pairs(tmpTable) do
        if tmpTable[key]:lower() == setspell then
            error('That spell is already set.')
            return
        end
    end
    if tonumber(slot) < 10 then slot = '0'..slot end
    --insert spell add code here
    for spell in spells:it() do
        if spell['english']:lower() == setspell then
            --This is where single spell setting code goes.
            --Need to set by spell id rather than name.
            windower.ffxi.set_blue_magic_spell(spell['id'], tonumber(slot))
            windower.send_command('@timers c "Blue Magic Cooldown" 60 up')
            tmpTable['slot'..slot] = setspell
        end
    end
    tmpTable = nil
end

function get_current_spellset()
    if windower.ffxi.get_player().main_job_id ~= 16 then return nil end
    return T(windower.ffxi.get_mjob_data().spells)
    -- Returns all values but 512
    :filter(function(id) return id ~= 512 end)
    -- Transforms them from IDs to lowercase English names
    :map(function(id) return spells[id].english:lower() end)
    -- Transform the keys from numeric x or xx to string 'slot0x' or 'slotxx'
    :key_map(function(slot) return ('slot%02u'):format(slot) end)
end

function remove_all_spells(trigger)
    windower.ffxi.reset_blue_magic_spells()
    notice('All spells removed.')
end

function save_set(setname)
    if setname == 'default' then
        error('Please choose a name other than default.')
        return
    end
    local curSpells = T(get_current_spellset())
    settings.spellsets[setname] = curSpells
    settings:save()
    atcfs('Set %s saved.', setname)
end

function get_spellset_list()
    log("Listing sets:")
    for key,_ in pairs(settings.spellsets) do
        if key ~= 'default' then
            local it = 0
            for i = 1, #settings.spellsets[key] do
                it = it + 1
            end
            log("\t"..key..' '..settings.spellsets[key]:length()..' spells.')
        end
    end
end

function get_spellset_content(spellset)
    log('Getting '..spellset..'\'s spell list:')
    settings.spellsets[spellset]:print()
end


--[[
Copyright (c) 2016 Ragnarok.Lorand
Original AzureSets Copyright (c) 2013, Ricky Gall
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
* Neither the name of azureSets nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL The Addon's Contributors BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]
