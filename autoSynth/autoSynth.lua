_addon.name = 'autoSynth'
_addon.author = 'Lorand'
_addon.commands = {'autoSynth', 'as'}
_addon.version = '1.3.3'
_addon.lastUpdate = '2016.09.25'

require('luau')
require('lor/lor_utils')
_libs.lor.include_addon_name = true
_libs.lor.req('all')

packets = require('packets')

synthesisPossible = false
baseDelay = 2
qualities = {[0]='NQ', [1]='Break', [2]='HQ'}
crystals = {[16]='Water',[17]='Wind',[18]='Fire',[19]='Earth',[20]='Lightning',[21]='Ice',[22]='Light',[23]='Dark'}
rarr = string.char(129,168)

compass = {n = -math.pi/2, s = math.pi/2, e = 0, w = math.pi, nw = -math.pi*3/4, ne = -math.pi*1/4, sw = math.pi*3/4, se = math.pi*1/4}
safe = {dark = 'n', light = 'ne', ice = 'e', wind = 'se', earth = 's', lightning = 'sw', water = 'w', fire = 'nw'}
risk = {dark = 'ne', light = 'n', ice = 'nw', wind = 'e', earth = 'se', lightning = 's', water = 'sw', fire = 'w'}

overall = {skillups = 0, skillup_count = 0, synths = 0, breaks = 0, hq = 0, hqT = {0,0,0}}
session = {skillups = 0, skillup_count = 0, synths = 0, breaks = 0, hq = 0, hqT = {0,0,0}}

qual_count_keys = {[1]='breaks',[2]='hq'}

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
                hq_msgs[#hq_msgs+1] = 'HQ%s: %d (%.2f%% overall / %.2f%% hq)':format(tier, count, tpct, hpct)
            end
            atcfs(' | ':join(hq_msgs))
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
end)

windower.register_event('addon command', function (command,...)
    command = command and command:lower() or 'help'
    local args = T{...}:map(string.lower)
    
    if command == 'reload' then
        windower.send_command('lua reload autoSynth')
    elseif command == 'unload' then
        windower.send_command('lua unload autoSynth')
    elseif S{'craft','start','on'}:contains(command) then
        synthesisPossible = true
        session = {skillups = 0, skillup_count = 0, synths = 0, breaks = 0, hq = 0, hqT = {0,0,0}}
        printStatus()
        trySynth()
    elseif S{'stop','end','off'}:contains(command) then
        synthesisPossible = false
        printStatus()
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

function printStatus()
    if not synthesisPossible then
        print_stats(session, 'Session')
    end
    atc(synthesisPossible and 'ON' or 'OFF')
end

function trySynth()
    if synthesisPossible then
        windower.send_command('input /lastsynth')
    end
end

function delayedAttempt()
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
        synthesisPossible = false
        printStatus()
    elseif original == 'You must wait longer before repeating that action.' then
        baseDelay = baseDelay + 1
        delayedAttempt()
    elseif original == 'You cannot use that command during synthesis.' then
        baseDelay = baseDelay + 2
        delayedAttempt()
    elseif original == 'Unable to execute that command. Your inventory is full.' then
        synthesisPossible = false
        printStatus()
    elseif original:match('%-+ %u%u Synthesis %(.+%) %-+') then --Block BattleMod synth messages
        return true
    elseif original:match('%-+ Break %(.+%) %-+') then
        return true
    elseif original:match('%-+ HQ Tier .! %-+') then
        return true
    end
end)

windower.register_event('incoming chunk', function(id,data)
    if id == 0x029 then
        local packetInfo = packets.parse('incoming', data)
        local pid = windower.ffxi.get_player().id
        if pid == packetInfo.Actor and packetInfo.Message == 38 then
            local amount = packetInfo['Param 2']/10
            overall.skillups = overall.skillups + amount
            overall.skillup_count = overall.skillup_count + 1
            session.skillups = session.skillups + amount
            session.skillup_count = session.skillup_count + 1
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
    return '%s:%s%s':format(h, (m < 10 and '0' or ''), m)
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

    return '%s-%s-%s':format(vanaYear, vanaMon, vanaDate)
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