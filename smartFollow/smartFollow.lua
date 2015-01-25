_addon.name = 'smartFollow'
_addon.author = 'Lorand'
_addon.commands = {'smartFollow', 'sf'}
_addon.version = '2.3'

--[[
	TODO:
	- Stop on dead / too far
	- Save/load settings
	- Set distance based on yalms & handle conversion to x/y distance
--]]

require('luau')
local Queue = require('queue')
local Pos = require('position')

local followTarget = false
local follow = false
local path = Queue.new()
local lastRec = 0
local lastMove = 0

local quadrants = {NW = {-1, 1}, SW = {1, -1}, NE = {0, -1}, SE = {0, 1}}
local compass = {N = -math.pi/2, S = math.pi/2, E = 0, W = math.pi, NW = -math.pi*3/4, NE = -math.pi*1/4, SW = math.pi*3/4, SE = math.pi*1/4}


windower.register_event('addon command', function (command,...)
    command = command and command:lower() or 'help'
    local args = {...}
	
	if command == 'reload' then
		windower.send_command('lua unload '.._addon.name..'; lua load '.._addon.name)
	elseif command == 'unload' then
		windower.send_command('lua unload '.._addon.name)
	elseif command == 'reset' then
		followTarget = nil
		follow = false
	elseif command == 'face' then
		face(args[1])
	elseif command == 'follow' then
		local name = args[1]
		if name == '<t>' then
			name = windower.ffxi.get_mob_by_target().name
		end
		if getPosition(name) then
			followTarget = args[1]
			follow = true
			windower.add_to_chat(0, '[smartFollow] Now following '..followTarget)
		else
			windower.add_to_chat(166, '[smartFollow] Error: unable to follow '..tostring(args[1]))
		end
	elseif S{'stop', 'pause', 'end', 'off'}:contains(command) then
		follow = false
		windower.ffxi.run(false)
		windower.add_to_chat(0, '[smartFollow] Deactivated')
	elseif S{'start', 'resume', 'on'}:contains(command) then
		if followTarget then
			follow = true
			windower.add_to_chat(0, '[smartFollow] Following '..followTarget)
		else
			windower.add_to_chat(166, '[smartFollow] Error: no follow target chosen')
		end
	elseif S{'toggle', 't'}:contains(command) then
		if followTarget then
			follow = not follow
		end
	else
		windower.add_to_chat(0, 'Error: Unknown command')
	end
end)

windower.register_event('prerender', function()
	local player = windower.ffxi.get_player()
	if follow and player and S{2,3}:contains(player.status_id) then
		follow = false
		windower.ffxi.run(false)
	elseif follow and (not player) then
		follow = false
	end

	local followee = nil
	if followTarget then
		followee = windower.ffxi.get_mob_by_name(followTarget)
	end
	
	if follow and followee then
		local now = os.clock()
		
		if (now - lastRec) > 0.3 then
			lastRec = now
			--Add a new waypoint if the followee has travelled far enough
			local targPos = getPosition(followTarget)
			if targPos ~= path:peekLast() then
				path:append(targPos)
			end
		end
		
		if (now - lastMove) > 0.4 then
			lastMove = now
			--If more than one waypoint is queued, then go to the next one.
			if path:size() > 1 then
				windower.ffxi.run(getDirRadian(getPosition(), path:pop()))
			else
				windower.ffxi.run(false)
			end
		end
	end
end)

--[[
	Get the position of the entity with the given name, or own
	position if no name is given.
--]]
function getPosition(name)
	name = name and name or windower.ffxi.get_player().name
	local mobChar = windower.ffxi.get_mob_by_name(name)
	if mobChar then
		return Pos.new(mobChar.x, mobChar.y, mobChar.z)
	end
	return nil
end

--[[
	Returns the direction in radians to face pos2 given pos1
--]]
function getDirRadian(pos1, pos2)
	if (not pos1) or (not pos2) then return nil end
	local dx = pos1:x() - pos2:x()
	local dy = pos1:y() - pos2:y()
	local quad = getQuadrant(dx, dy)
	local theta = math.atan(math.abs(dy)/math.abs(dx))
	local phi = (math.pi * quadrants[quad][1]) + (theta * quadrants[quad][2])
	return phi
end

--[[
	Returns the quandrant in which the given point lies
--]]
function getQuadrant(x, y)
	if (not x) or (not y) then return nil end
	local quad = (y > 0 and 'S' or 'N')
	quad = quad .. (x > 0 and 'W' or 'E')
	return quad
end

--[[
	Turn to face the given entity
--]]
function face(name)
	if not name then return end
	local myPos = getPosition()
	local mobPos = getPosition(name)
	if myPos and mobPos then
		windower.ffxi.turn(getDirRadian(myPos, mobPos))
	elseif compass[name] then
		windower.ffxi.turn(compass[name])
	end
end

-----------------------------------------------------------------------------------------------------------
--[[
Copyright © 2014, Lorand
All rights reserved.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of ffxiHealer nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Lorand BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]
-----------------------------------------------------------------------------------------------------------