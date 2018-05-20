_addon.name = 'infoBoxes'
_addon.author = 'Lorand'
_addon.commands = {'infoBoxes', 'ib'}
_addon.version = '1.1.3'
_addon.lastUpdate = '2016.10.01'

require('lor/lor_utils')
_libs.lor.include_addon_name = true
_libs.lor.req('all')

require('sets')
require('actions')
local res = require('resources')
local InfoBox = require('infoBox')
local start_time = os.time()
local strat_charge_time = {[1]=240,[2]=120,[3]=80,[4]=60,[5]=48}

local boxSettings = {}
boxSettings.stratagems = {pos = {x = -300, y = -20}, flags = {bottom = true, right = true}}
boxSettings.target = {pos = {x = -125, y = 250}, flags = {bottom = false, right = true}}
boxSettings.targHp = {pos = {x = -125, y = 270}, flags = {bottom = false, right = true}}
boxSettings.acc = {pos = {x = -125, y = -20}, flags = {bottom = true, right = true}}
boxSettings.speed = {pos = {x = -60, y = -20}, flags = {bottom = true, right = true}}
boxSettings.dist = {pos = {x = -178, y = 21}, text = {font='Arial', size = 14}, flags = {right = true}}
boxSettings.zt = {pos = {x = -100, y = 0}, text = {font='Arial', size = 12}, flags = {right = true}}
boxSettings.mobHp = {pos={x=400,y=0}}
boxSettings.track = {pos={x=800,y=0}}

local boxes = {}
local player
local acc = {hits = 0, misses = 0}
local track = T{}

windower.register_event('load', 'login', function()
	player = windower.ffxi.get_player()
	boxes.stratagems = InfoBox.new(boxSettings.stratagems, 'Stratagems')
	boxes.target = InfoBox.new(boxSettings.target)
	boxes.targHp = InfoBox.new(boxSettings.targHp, 'HP')
	boxes.acc = InfoBox.new(boxSettings.acc, 'Acc')
	boxes.speed = InfoBox.new(boxSettings.speed)
	boxes.dist = InfoBox.new(boxSettings.dist)
	boxes.zt = InfoBox.new(boxSettings.zt)
	boxes.mobHp = InfoBox.new(boxSettings.mobHp)
    boxes.track = T{}
end)

windower.register_event('logout', function()
	player = nil
end)

windower.register_event('zone change', function(new_zone, old_zone)
	start_time = os.time()
	player = windower.ffxi.get_player()
end)

windower.register_event('addon command', function(command,...)
    command = command and command:lower() or 'help'
    local args = {...}
	
	if command == 'reload' then
		windower.send_command('lua unload '.._addon.name..'; lua load '.._addon.name)
	elseif command == 'unload' then
		windower.send_command('lua unload '.._addon.name)
	elseif command == 'reset' then
		acc.hits = 0
		acc.misses = 0
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
	else
		windower.add_to_chat(0, 'Error: Unable to parse valid command')
	end
end)


function untrack_mob(idx)
    if track[idx] ~= nil then
        track:remove(idx)
        boxes.track[idx]:hide()
        boxes.track:remove(idx)
        while idx <= #boxes.track do
            local x,y = boxes.track[idx]:getPos()
            if y > 0 then
                boxes.track[idx]:setPos(x,y-16)
            end
            idx = idx + 1
        end
    end
end


function track_mob(id)
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
                atc(123,'Already tracking that mob!')
                return
            end
        end
        track:append({id = mob_id, tod = nil})
        local y_pos = boxSettings.track.pos.y - 16
        if #boxes.track > 0 then
            _,y_pos = boxes.track[#boxes.track]:getPos()
        end
        boxes.track:append(InfoBox.new({pos={x=boxSettings.track.pos.x,y=y_pos + 16}}))
        atcfs('Now tracking %s', mob_id)
    end
end


windower.register_event('prerender', function()
	if player then
        local now = os.time()
		boxes.zt:updateContents(os.date('!%H:%M:%S', now-start_time))
		
		local me = windower.ffxi.get_mob_by_target('me')
		if me then
			boxes.speed:updateContents(('%+.0f %%'):format(100*((me.movement_speed/5)-1)))
		else
			boxes.speed:hide()
		end
		
		if S{player.main_job, player.sub_job}:contains('SCH') then
			boxes.stratagems:updateContents(get_available_stratagem_count())
		else
			boxes.stratagems:hide()
		end
		
		local target = windower.ffxi.get_mob_by_target()
		--local tindex = windower.ffxi.get_player().target_index
		--target = target or (tindex and windower.ffxi.get_mob_by_index(tindex))
		if target ~= nil then
			local target_t = windower.ffxi.get_mob_by_index(target.target_index)
			if target_t ~= nil then
				boxes.target:updateContents(target.name..' → '..target_t.name)
			else
				boxes.target:updateContents(target.name)
			end
			boxes.targHp:updateContents(target.hpp..'%')
			boxes.dist:updateContents(('%.1f'):format(target.distance:sqrt()))
			
			if (target.is_npc) then
				lastTarget = target.id
			end
		else
			boxes.target:hide()
			boxes.targHp:hide()
			boxes.dist:hide()
		end
		
        for tidx,_track in pairs(track) do      
            if _track.id ~= nil then
                local tracked = windower.ffxi.get_mob_by_id(_track.id)
                if tracked ~= nil then
                    if tracked.hpp > 0 then
                        boxes.track[tidx]:updateContents(('%s is UP!'):format(tracked.name))
                        _track.tod = nil
                    elseif _track.tod == nil then
                        _track.tod = now
                    else
                        boxes.track[tidx]:updateContents(('%s %s'):format(os.date('!%H:%M:%S', now - _track.tod), tracked.name))
                    end
                end
            end
        end
        
		if (lastTarget ~= nil) then
			local lastMob = windower.ffxi.get_mob_by_id(lastTarget)
			if (lastMob ~= nil) then
				boxes.mobHp:updateContents(lastMob.name..': '..lastMob.hpp..'%')
			end
		else
			boxes.mobHp:hide()
		end
		
		if (acc.hits ~= 0) or (acc.misses ~= 0) then
			boxes.acc:updateContents(calcAcc())
		else
			boxes.acc:hide()
		end
	else
		for _,box in pairs(boxes) do
            if class(box) ~= 'InfoBox' then
                for _,sbox in pairs(box) do
                    box:hide()
                end
            else
                box:hide()
            end
		end
	end
end)


windower.register_event('action', function(_raw)
	local action = Action(_raw.category, _raw.param, _raw)
	if action ~= nil then
		if (action.raw.actor_id == player.id) and (action.raw.category == 'melee') then
			for _,target in pairs(action.raw.targets) do
				for _,subaction in pairs(target.actions) do
					if subaction.message == 1 or subaction.message == 67 then
						acc.hits = acc.hits + 1
					elseif subaction.message == 15 or subaction.message == 63 then
						acc.misses = acc.misses + 1
					end
				end
			end
		end
	end
end)

function calcAcc()
	local swings = acc.hits + acc.misses
	if swings == 0 then return '0%' end
	local pct = acc.hits / swings
	pct = math.floor(pct*10000)/100
	return tostring(pct)..'%'
end

--[[
	Calculates and returns the maximum number of SCH stratagems available for use.
--]]
function get_max_stratagem_count()
	if S{player.main_job, player.sub_job}:contains('SCH') then
		local lvl = player.main_job == 'SCH' and player.main_job_level or player.sub_job_level
		return math.floor(((lvl  - 10) / 20) + 1)
	else
		return 0
	end
end

--[[
	Calculates the number of SCH stratagems that are currently available for use. Calculated from the combined recast timer for stratagems and the maximum number
	of stratagems that are available.  The recast time for each stratagem charge corresponds directly with the maximum number of stratagems that can be used.
--]]
function get_available_stratagem_count()
	local recastTime = windower.ffxi.get_ability_recasts()[231] or 0
	local maxStrats = get_max_stratagem_count()
	if maxStrats == 0 then return 0 end
	local stratsUsed = (recastTime/strat_charge_time[maxStrats]):ceil()
	return maxStrats - stratsUsed
end

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
