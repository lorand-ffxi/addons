_addon.name = 'autoSynth'
_addon.author = 'Lorand'
_addon.commands = {'autoSynth', 'as'}
_addon.version = '1.5.1'
_addon.lastUpdate = '2016.11.26'

require('luau')
require('lor/lor_utils')
_libs.lor.include_addon_name = true
_libs.req('texts')
_libs.lor.req('all')

local packets = require('packets')

local synthesisPossible = false
local baseDelay = 2.1
local qualities = {[0]='NQ', [1]='Break', [2]='HQ'}
local crystals = {[16]='Water',[17]='Wind',[18]='Fire',[19]='Earth',[20]='Lightning',[21]='Ice',[22]='Light',[23]='Dark'}
local qual_count_keys = {[1]='breaks',[2]='hq'}
local rarr = string.char(129,168)

local compass = {n = -math.pi/2, s = math.pi/2, e = 0, w = math.pi, nw = -math.pi*3/4, ne = -math.pi*1/4, sw = math.pi*3/4, se = math.pi*1/4}
local safe = {dark = 'n', light = 'ne', ice = 'e', wind = 'se', earth = 's', lightning = 'sw', water = 'w', fire = 'nw'}
local risk = {dark = 'ne', light = 'n', ice = 'nw', wind = 'e', earth = 'se', lightning = 's', water = 'sw', fire = 'w'}

local overall = {skillups = 0, skillup_count = 0, synths = 0, breaks = 0, hq = 0, hqT = {0,0,0}}
local session = {skillups = 0, skillup_count = 0, synths = 0, breaks = 0, hq = 0, hqT = {0,0,0}}
local req_food = false
local req_supp = false
local queued = -1
local stop_skill
local stop_level = -1

local saved_info = _libs.lor.settings.load('data/saved_info.lua')
local default_skill_box_settings = {skill_box={pos={x=-400,y=0}, flags={right=true,bottom=false}, text={font='Arial',size=10}}}
local skill_box_settings = _libs.lor.settings.load('data/settings.lua', default_skill_box_settings).skill_box
local skill_box
local lc_skills

_debug = false


function print_stats(stats, header)
    atcfs('%s stats:', header)
    if stats.skillup_count > 0 then
        local pl = (stats.skillup_count > 1) and 's' or ''
        atcfs('Skill increase: %.1f (%d skillup%s) | Avg: %.2f per skillup, %.2f per synth | Rate: %.2f%%', stats.skillups, stats.skillup_count, pl, stats.skillups/stats.skillup_count, stats.skillups/stats.synths, stats.skillup_count/stats.synths*100)
    else
        atc('No skillups.')
    end
        
    if stats.synths > 0 then
        atcfs('Total: %d synths | HQ: %d (%.2f%%) | Break: %d (%.2f%%)', stats.synths, stats.hq, stats.hq/stats.synths*100, stats.breaks, stats.breaks/stats.synths*100)
        if stats.hq > 0 then
            local hq_msgs = {}
            for tier, count in ipairs(stats.hqT) do
                local tpct, hpct = count/stats.synths*100, count/stats.hq*100
                hq_msgs[#hq_msgs+1] = ('HQ%s: %d (%.2f%% overall / %.2f%% hq)'):format(tier, count, tpct, hpct)
            end
            atcfs((' | '):join(hq_msgs))
        end
    else
        atc('No synths performed.')
    end
end


windower.register_event('load', function()
    atc('Loaded autoSynth.')
    atc('AutoSynth will repeat the most recent synthesis attempt via /lastsynth until you run out of materials, or it is stopped manually.')
    atc('Commands:')
    atc('//autoSynth start')
    atc('//autoSynth stop')
    
    local player = windower.ffxi.get_player()
    update_current_skill(player)
    refresh_skill_box(player)
    
    lc_skills = {}
    for _,skill in pairs(res.skills) do
        lc_skills[skill.en:lower()] = skill
    end
end)


windower.register_event('addon command', function (command,...)
    command = command and command:lower() or 'help'
    local args = T{...}:map(string.lower)
    
    if S{'reload','unload'}:contains(command) then
        windower.send_command(('lua %s %s'):format(command, _addon.name))
    elseif S{'craft','start','on'}:contains(command) then
        start_session()
    elseif S{'stop','end','off'}:contains(command) then
        stop_session()
    elseif S{'require','req'}:contains(command) then
        for _,arg in pairs(args) do
            if S{'food'}:contains(arg) then
                req_food = true
                atc('Will stop crafting when food wears off.')
            elseif S{'support','supp','imagery'}:contains(arg) then
                req_supp = true
                atc('Will stop crafting when crafting imagery wears off.')
            else
                atcfs('Unrecognized argument for require: %s', arg)
            end
        end
    elseif S{'cancel','no','noreq','norequire','cancelreq'}:contains(command) then
        for _,arg in pairs(args) do
            if S{'food'}:contains(arg) then
                req_food = false
                atc('Will continue crafting if food wears off.')
            elseif S{'support','supp','imagery'}:contains(arg) then
                req_supp = false
                atc('Will continue crafting if crafting imagery wears off.')
            else
                atcfs('Unrecognized argument for cancel requirement: %s', arg)
            end
        end
    elseif S{'make','craft','do','batch'}:contains(command) then
        if tonumber(args[1]) then
            queued = tonumber(args[1])
            start_session()
        else
            atcfs('Usage: %s <number>', command)
        end
    elseif S{'until','til','level'}:contains(command) then
        if (args[1] ~= nil) and tonumber(args[2]) then
            local arg_skill = lc_skills[args[1]:lower()]
            if arg_skill ~= nil then
                if arg_skill.category == 'Synthesis' then                
                    stop_skill = args[1]
                    stop_level = tonumber(args[2])
                    start_session()
                else
                    atcfs('Invalid skill: %s (only supports crafting skills)', args[1])
                end
            else
                atcfs('Invalid skill: %s', args[1])
            end
        else
            atcfs('Usage: %s <skill> <number>', command)
        end
    elseif command == 'debug' then
        _debug = not _debug
        atcfs('Debug mode: %s', _debug)
    elseif command == 'attempt' then
        trySynth()
    elseif S{'stat','stats','count','counts'}:contains(command) then
        print_stats(overall, 'Total')
    elseif S{'turn', 'face'}:contains(command) then
        face(args)
    end
end)

function printStatus()
    if not synthesisPossible then
        print_stats(session, 'Session')
    end
    atc(synthesisPossible and 'ON' or 'OFF')
end

function trySynth()
    check_buffs()
    if synthesisPossible then
        windower.send_command('input /lastsynth')
        queued = queued - 1
    end
end

function start_session()
    synthesisPossible = true
    session = {skillups = 0, skillup_count = 0, synths = 0, breaks = 0, hq = 0, hqT = {0,0,0}}
    printStatus()
    trySynth()
end

function stop_session(col, msg)
    if not synthesisPossible then return end
    synthesisPossible = false
    queued = -1
    stop_skill = nil
    stop_level = -1
    if msg ~= nil then
        atc(col, msg)
    end
    printStatus()
end

function check_buffs()
    local player = windower.ffxi.get_player()
    local active_buffs = S(player.buffs)
    
    if req_food and (not active_buffs[251]) then
        stop_session(123, 'Food wore off - cancelling synthesis')
    end
    
    if req_supp then
        local has_supp = false
        for i = 235, 243 do
            if active_buffs[i] then
                has_supp = true
                break
            end
        end
        if not has_supp then
            stop_session(123, 'Synthesis imagery wore off - cancelling synthesis')
        end
    end
    
    if queued == 0 then
        stop_session(1, 'Completed batch.')
    elseif stop_level > 0 then
        if player.skills[stop_skill] >= stop_level then
            stop_session(1, ('Reached skill goal [%s %s >= %s]'):format(stop_skill, player.skills[stop_skill], stop_level))
        end
    end
end

function delayedAttempt()
    check_buffs()
    if synthesisPossible then
        local waitTime = baseDelay + math.random(0, 2)
        if _debug then
            atcfs('Initiating synthesis attempt in %ss', waitTime)
        end
        windower.send_command('wait '..waitTime..'; autoSynth attempt')
    end
end

windower.register_event('incoming text', function(original)
    if string.contains(original, 'Synthesis canceled.') then
        stop_session()
    elseif original == 'You must wait longer before repeating that action.' then
        baseDelay = baseDelay + 1
        if queued > -1 then
            queued = queued + 1
        end
        delayedAttempt()
    elseif original == 'You cannot use that command during synthesis.' then
        baseDelay = baseDelay + 2
        if queued > -1 then
            queued = queued + 1
        end
        delayedAttempt()
    elseif original == 'Unable to execute that command. Your inventory is full.' then
        stop_session()
    elseif original:match('%-+ %u%u Synthesis %(.+%) %-+') then --Block BattleMod synth messages
        return true
    elseif original:match('%-+ Break %(.+%) %-+') then
        return true
    elseif original:match('%-+ HQ Tier .! %-+') then
        return true
    end
end)


function register_skillup(packetInfo)
    if S{38,53}:contains(packetInfo.Message) then
        local skill = res.skills[packetInfo['Param 1']]
        if skill.category ~= 'Synthesis' then return end
        local player = windower.ffxi.get_player()
        if packetInfo.Message == 38 then
            update_current_skill(player, skill.en:lower(), packetInfo['Param 2'])
        elseif packetInfo.Message == 53 then
            update_current_skill(player, skill.en:lower(), nil, packetInfo['Param 2'])
        end
        refresh_skill_box(player)
    end
end


function update_current_skill(player, skill_name, incr, lvl)
    player = player or windower.ffxi.get_player()
    local do_save = false
    if saved_info[player.name] == nil then
        saved_info[player.name] = {}
        do_save = true
    end
    skill_name = skill_name or saved_info[player.name].last_skillup
    if skill_name == nil then return end
    if saved_info[player.name][skill_name] == nil then
        saved_info[player.name][skill_name] = player.skills[skill_name]
        do_save = true
    end
    if saved_info[player.name].last_skillup ~= skill_name then
        saved_info[player.name].last_skillup = skill_name
        do_save = true
    end
    if player.skills[skill_name] > saved_info[player.name][skill_name] then
        saved_info[player.name][skill_name] = player.skills[skill_name]
        do_save = true
    end
    if incr then
        saved_info[player.name][skill_name] = saved_info[player.name][skill_name] + (incr / 10)
        do_save = true
    elseif lvl then
        if lvl > saved_info[player.name][skill_name] then
            saved_info[player.name][skill_name] = lvl
            do_save = true
        end
    end
    if do_save then
        saved_info:save(true)
    end
end


function refresh_skill_box(player)
    if skill_box == nil then
        skill_box = _libs.texts.new(skill_box_settings)
    end
    player = player or windower.ffxi.get_player()
    if player ~= nil then
        if saved_info[player.name] ~= nil then
            local skill_name = saved_info[player.name].last_skillup
            if skill_name == nil then return end
            local skill_val = saved_info[player.name][skill_name] or 0
            skill_box:text(('%s: %.1f'):format(skill_name, skill_val))
            skill_box:visible(true)
        end
    end
end


windower.register_event('incoming chunk', function(id,data)
    if id == 0x029 then
        local packetInfo = packets.parse('incoming', data)
        local pid = windower.ffxi.get_player().id
        if pid == packetInfo.Actor then
            register_skillup(packetInfo)
            if packetInfo.Message == 38 then
                local amount = packetInfo['Param 2']/10
                overall.skillups = overall.skillups + amount
                overall.skillup_count = overall.skillup_count + 1
                session.skillups = session.skillups + amount
                session.skillup_count = session.skillup_count + 1
            end
        end
    elseif id == 0x030 then
        local packetInfo = packets.parse('incoming', data)
        if windower.ffxi.get_player().id == packetInfo.Player then
            local ffInfo = windower.ffxi.get_info()
            local mphase = res.moon_phases[ffInfo.moon_phase].en .. ' (' .. ffInfo.moon .. '%)'
            local zone = res.zones[ffInfo.zone].en
            local day = res.days[ffInfo.day].en
            local weather = res.weather[ffInfo.weather].en
            local vTime = getVtime(ffInfo.time)
        
            local result = packetInfo.Param
            local element = packetInfo.Effect
            
            atcfs(8, 'Initiating %s synthesis (%s) | %s | %s | %s | %s | %s | %s', crystals[element], qualities[result], getVanadielTime(), vTime, day, weather, mphase, zone)
            local qck = qual_count_keys[result]
            if qck ~= nil then
                overall[qck] = overall[qck] + 1
                session[qck] = session[qck] + 1
            end
            overall.synths = overall.synths + 1
            session.synths = session.synths + 1
        end
    elseif id == 0x06F then
        local p = data:sub(5)
        if p:byte(1) == 0 then
            local result = p:byte(2)
            if result > 0 then
                atcfs(8, ' %s HQ Tier %s!', rarr, result)
                overall.hqT[result] = overall.hqT[result] + 1
                session.hqT[result] = session.hqT[result] + 1
            end
        end
        if _debug then
            atc('Synthesis complete')
        end
        delayedAttempt()
    end
end)

function getVtime(rawVtime)
    local m = rawVtime % 60
    local h = (rawVtime - m)/60
    return ('%s:%s%s'):format(h, (m < 10 and '0' or ''), m)
end

function getVanadielTime()
    local basisTime = os.time{year=2002, month=6, day=23, hour=11, min=0}   --FFXI epoch
    local basisDate = os.date('!*t', basisTime)
    local basisMs = os.time(basisDate)*1000
    local now = os.time(os.date('!*t', os.time()))*1000
    
    local msGameDay = (24 * 60 * 60 * 1000 / 25)                    -- milliseconds in a game day
    local msRealDay = (24 * 60 * 60 * 1000)                         -- milliseconds in a real day
    
    local vanaDate =  ((898 * 360 + 30) * msRealDay) + (now - basisMs) * 25 + 1250000

    local vYear = math.floor(vanaDate / (360 * msRealDay))
    local vMon  = math.floor((vanaDate % (360 * msRealDay)) / (30 * msRealDay)) + 1
    local vDate = math.floor((vanaDate % (30 * msRealDay)) / (msRealDay)) + 1
    local vHour = math.floor((vanaDate % (msRealDay)) / (60 * 60 * 1000))
    local vMin  = math.floor((vanaDate % (60 * 60 * 1000)) / (60 * 1000))
    local vSec  = math.floor((vanaDate % (60 * 1000)) / 1000)
    local vDay  = math.floor((vanaDate % (8 * msRealDay)) / (msRealDay))
    
    local vanaYear = (vYear < 1000) and '0'..vYear or vYear
    local vanaMon = (vMon < 10) and '0'..vMon or vMon
    local vanaDate = (vDate < 10) and '0'..vDate or vDate
    local vanaHour = (vHour < 10) and '0'..vHour or vHour
    local vanaMin = (vMin < 10) and '0'..vMin or vMin
    local vanaSec = (vSec < 10) and '0'..vSec or vSec

    return ('%s-%s-%s'):format(vanaYear, vanaMon, vanaDate)
end

function face(args)
    if args[1] ~= nil then
        if args[2] ~= nil then
            if S{'safe', 'nq'}:contains(args[1]) then
                if safe[args[2]] ~= nil then
                    windower.ffxi.turn(compass[safe[args[2]]])
                else
                    atcfs('Error: invalid element: %s', args[2])
                end
            elseif S{'risk', 'hq'}:contains(args[1]) then
                if risk[args[2]] ~= nil then
                    windower.ffxi.turn(compass[risk[args[2]]])
                else
                    atcfs('Error: invalid element: %s', args[2])
                end
            else
                atcfs('Error: invalid direction type: %s', args[1])
            end
        elseif compass[args[1]] ~= nil then
            windower.ffxi.turn(compass[args[1]])
        else
            atcfs('Error: invalid command or too few arguments.')
        end
    else
        atc('Error: too few arguments.')
    end
end

-----------------------------------------------------------------------------------------------------------
--[[
Copyright © 2016, Lorand
All rights reserved.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of autoSynth nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Lorand BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]
-----------------------------------------------------------------------------------------------------------
