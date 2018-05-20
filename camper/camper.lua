_addon.name = 'camper'
_addon.author = 'Lorand'
_addon.commands = {'camper', 'camp'}
_addon.version = '1.1.0'
_addon.lastUpdate = '2016.10.02.01'

require('lor/lor_utils')
_libs.lor.include_addon_name = true
_libs.lor.req('all')

require('sets')
require('actions')
local res = require('resources')
local texts = require('texts')

local defaults = {box_pos={x=800,y=0}, zones={}}
settings = _libs.lor.settings.load('data/settings.lua', defaults)

local boxes = T{}
local player
local zone
local track = T{}
local find_mobs = S{}
local last_find_scan = os.time()
local find_scan_delay = 1


local function refresh_vars()
    player = windower.ffxi.get_player()
    local zone_id = windower.ffxi.get_info().zone
    zone = res.zones[zone_id].en
    if settings.zones[zone] ~= nil then
        for mob_id,_ in pairs(settings.zones[zone]) do
            track_mob(mob_id, true)
        end
    end
end


windower.register_event('load', 'login', function()
    refresh_vars()
end)

windower.register_event('logout', function()
	player = nil
end)

windower.register_event('zone change', function(new_zone, old_zone)
    refresh_vars()
end)

windower.register_event('addon command', function(command,...)
    command = command and command:lower() or 'help'
    local args = {...}
	
	if command == 'reload' then
		windower.send_command(('lua unload %s; lua load %s'):format(_addon.name, _addon.name))
	elseif command == 'unload' then
		windower.send_command(('lua unload %s'):format(_addon.name))
    elseif command == 'find' then
        find_mob((" "):join(args), true)
    elseif command == 'stop_find' then
        find_mob((" "):join(args), false)
    elseif command == 'track' then
        track_mob(args[1])
    elseif command == 'untrack' then
        if args[1] == nil then
            atc(123, 'Missing argument for untrack: index number')
        elseif not isnum(args[1]) then
            untrack_mob(tonumber(args[1]))
        else
            atc(123, 'Invalid arg for untrack')
        end
    elseif command == 'list' then
        pprint(pycomp('mob.id, mob.name for _,mob in windower.ffxi.get_mob_array()'))
	else
		atc(0, 'Error: Unable to parse valid command')
	end
end)


function find_mob(mob_name, add)
    local do_add = true
    if add ~= nil then do_add = add end
    local mname = mob_name:lower()
    if find_mobs:contains(mname) then
        if do_add then
            atc(123,'Already looking for that mob!')
        else
            find_mobs:remove(mname)
            atcfs('Will stop searching for %s', mname)
        end
    else
        if do_add then
            find_mobs:add(mname)
            atcfs('Will now search for %s', mname)
        else
            atc(123,'That mob was not being searched for anyways!')
        end
    end
end


function untrack_mob(idx)
    if track[idx] ~= nil then
        track:remove(idx)
        boxes[idx]:hide()
        boxes:remove(idx)
        while idx <= #boxes do
            local x, y = boxes[idx]:pos()
            if y > 0 then
                boxes[idx]:pos(x, y - 16)
            end
            idx = idx + 1
        end
    end
end


local function get_track_ids()
    local ids = S{}
    for _,cfg in pairs(track) do
        ids:add(cfg.id)
    end
    return ids
end


function track_mob(id, auto_loading)
    local mob_id
    if id ~= nil then
        mob_id = tonumber(id)
    else
        local mob = windower.ffxi.get_mob_by_target()
        if mob ~= nil then
            mob_id = mob.id
        end
    end
    
    if mob_id ~= nil then
        for _,cfg in pairs(track) do
            if cfg.id == mob_id then
                if not auto_loading then
                    atc(123,'Already tracking that mob!')
                end
                return
            end
        end
        if not auto_loading then
            settings.zones[zone] = settings.zones[zone] or {}
            settings.zones[zone][mob_id] = settings.zones[zone][mob_id] or {}
            settings:save(true)
        end
        
        local to_be_tracked = {
            id = mob_id,
            ['zone'] = zone,
            tod = settings.zones[zone][mob_id].tod,
            name = settings.zones[zone][mob_id].name
        }
        track:append(to_be_tracked)
        local y_pos = settings.box_pos.y - 16
        if #boxes > 0 then
            _,y_pos = boxes[#boxes]:pos()
        end
        boxes:append(texts.new({pos={x=settings.box_pos.x, y=y_pos + 16}}))
        atcfs('Now tracking %s', mob_id)
    end
end


windower.register_event('prerender', function()
	if player then
        local now = os.time()
        
        if (#table.keys(find_mobs) > 0) and ((now - last_find_scan) > find_scan_delay) then
            last_find_scan = now
            for _,mob in pairs(windower.ffxi.get_mob_array()) do
                if find_mobs:contains(mob.name:lower()) and (not get_track_ids():contains(mob.id)) then
                    track_mob(mob.id)
                end
            end
        end
        
        for tidx, _track in pairs(track) do
            if _track.id ~= nil then
                local mob_up = false
                local mob_dist = ''
                if _track.zone == zone then
                    local tracked = windower.ffxi.get_mob_by_id(_track.id)
                    if tracked ~= nil then
                        if (settings.zones[zone][_track.id].name == nil) or (settings.zones[zone][_track.id].name == '') then
                            settings.zones[zone][_track.id].name = tracked.name
                            settings:save(true)
                        end
                        if _track.name == nil then
                            _track.name = tracked.name
                        end
                        if tracked.hpp > 0 then
                            mob_up = true
                            _track.tod = nil
                            if settings.zones[zone][_track.id].tod ~= nil then
                                settings.zones[zone][_track.id].tod = nil
                                settings:save(true)
                            end
                        elseif _track.tod == nil then
                            _track.tod = now
                            settings.zones[zone][_track.id].tod = now
                            settings:save(true)
                        end
                        mob_dist = (' (%.1f)'):format(tracked.distance:sqrt())
                    end
                end
                
                local mob_name = _track.name or '[Unknown]'
                if mob_up then
                    boxes[tidx]:text(('%s is UP! %s'):format(mob_name, mob_dist))
                else
                    local dtime = '--:--:--'
                    if _track.tod ~= nil then
                        dtime = os.date('!%H:%M:%S', now - _track.tod)
                    end
                    boxes[tidx]:text(('%s %s%s'):format(dtime, mob_name, mob_dist))
                end
                boxes[tidx]:show()
            end
        end
	else
		for _,box in pairs(boxes) do
            box:hide()
		end
	end
end)

-----------------------------------------------------------------------------------------------------------
--[[
Copyright © 2016, Lorand
All rights reserved.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of info nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Lorand BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]
-----------------------------------------------------------------------------------------------------------
