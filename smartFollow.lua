_addon.name = 'smartFollow'
_addon.author = 'Lorand'
_addon.commands = {'smartFollow', 'sf'}
_addon.version = '2.0 beta'

--[[
	TODO:
	- Stop on dead / too far
	- Save/load settings
	- Set distance based on yalms & handle conversion to x/y distance
--]]

require('luau')
local Queue = require('queue')
local Pos = require('position')

local followTarget = ''
local follow = false
local followDistance = 2
local stuck = 0
local lastPos = {}
local path = Queue.new()

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
		followTarget = ''
		follow = false
		followDistance = 2
		lastPos = {}
		stuck = 0
	elseif command == 'face' then
		face(args[1])
	elseif command == 'follow' then
		local name = args[1]
		if name == '<t>' then
			name = windower.ffxi.get_mob_by_target().name
		end
		local tPos = getPosition(name)
		if tPos ~= nil then
			followTarget = args[1]
			targetPos = tPos
			follow = true
			windower.add_to_chat(0, '[smartFollow] Now following '..followTarget)
		else
			windower.add_to_chat(166, '[smartFollow] Error: unable to follow '..tostring(args[1]))
		end
	elseif S{'distance', 'dist'}:contains(command) then
		local d = tonumber(args[1])
		if (d ~= nil) and (0 < d) and (d < 30) then
			followDistance = d
			windower.add_to_chat(0, '[smartFollow] Follow distance set to '..followDistance)
		else
			windower.add_to_chat(166, '[smartFollow] Error: invalid follow distance.')
		end
	elseif S{'stop', 'pause', 'end', 'off'}:contains(command) then
		follow = false
		windower.ffxi.run(false)
		windower.add_to_chat(0, '[smartFollow] Deactivated')
	elseif S{'start', 'resume', 'on'}:contains(command) then
		if followTarget ~= '' then
			follow = true
			windower.add_to_chat(0, '[smartFollow] Following '..followTarget)
		else
			windower.add_to_chat(166, '[smartFollow] Error: no follow target chosen')
		end
	elseif S{'toggle', 't'}:contains(command) then
		if followTarget ~= nil then
			follow = not follow
		end
	else
		windower.add_to_chat(0, 'Error: Unknown command')
	end
end)

windower.register_event('prerender', function()
	if follow and (followTarget ~= '') then
		followPath()
	end
end)

function followTarget()
	local dist = getDistance(followTarget)
	if dist == nil then
		follow = false
		windower.ffxi.run(false)
		windower.add_to_chat(0, '[smartFollow] Deactivated - could not find target')
		return
	end
	
	if dist > followDistance then
		local pos = getPosition()
		if lastPos ~= {} then
			if (pos.x == lastPos.x) and (pos.y == lastPos.y) then
				stuck = stuck + 1
			else
				stuck = 0
			end
		end
		lastPos = pos
		
		local phi = getFaceDir(followTarget)
	
		if stuck > 30 then			
			local dx, dy = getDistancesXY(followTarget)
			if (dx == nil) or (dy == nil) then return end
			
			local n,s,e,w = getNSEW(dx, dy)
			dx = math.abs(dx)
			dy = math.abs(dy)
			
			if (dy > dx) and (dx > 1) then
				if n and e then		--Further North than East
					phi = 0				-->Go East
				elseif n and w then	--Further North than West
					phi = math.pi		-->Go West
				elseif s and e then	--Further South than East
					phi = 0				-->Go East
				elseif s and w then	--Further South than West
					phi = math.pi		-->Go West
				end
			elseif (dx > dy) and (dy > 1) then
				if n and e then		--Further East than North
					phi = -math.pi/2	-->Go North
				elseif n and w then	--Further West than North
					phi = -math.pi/2	-->Go North
				elseif s and e then	--Further East than South
					phi = math.pi/2		-->Go South
				elseif s and w then	--Further West than South
					phi = math.pi/2		-->Go South
				end
			end
		end
		windower.ffxi.run(phi)
	else
		windower.ffxi.run(false)
	end
end

function followPath()
	--Record target's position as a waypoint
	local targPos = getPosition(followTarget)
	local lastPos = path:getLast()
	if not targPos:equals(lastPos) then
		path:add(targPos)
	end
	
	--Advance to the next waypoint if far enough away
	local currentPos = getPosition()
	local dist = currentPos:getDistance(path:getFirst())
	if dist > followDistance then
		local npos = path:getNext()
		local dx = currentPos:x() - npos:x()
		local dy = currentPos:y() - npos:y()
		local phi = getFaceDirection(dx, dy)
		windower.ffxi.run(phi)
	else
		windower.ffxi.run(false)
	end
end

--[[
	Turn to face the given entity
--]]
function face(name)
	if name == nil then return end
	local mob = windower.ffxi.get_mob_by_name(name)
	if mob ~= nil then
		local phi = getFaceDir(name)
		if phi ~= nil then
			windower.ffxi.turn(phi)
		end
	elseif compass[name] ~= nil then
		windower.ffxi.turn(compass[name])
	end
end

--[[
	Get the difference in x and y coordinates between the player and the given target
--]]
function getDistancesXY(name)
	local myName = windower.ffxi.get_player().name
	if myName == name then return nil, nil end
	local mobMe = windower.ffxi.get_mob_by_name(myName)
	local mobTarg = windower.ffxi.get_mob_by_name(name)
	if (mobTarg == nil) or (mobMe == nil) then return nil, nil end
	
	local dx = mobMe.x - mobTarg.x	--Target further east than player -> negative
	local dy = mobMe.y - mobTarg.y	--Target further north than player -> negative
	return dx, dy
end

--[[
	Get the direction in radians that faces the given target
--]]
function getFaceDir(name)
	local dx, dy = getDistancesXY(name)
	return getFaceDirection(dx, dy)
end

function getQuadrant(dx, dy)
	if (dx == nil) or (dy == nil) then return nil end
	
	local quad = (dy > 0 and 'S' or 'N')
	quad = quad .. (dx > 0 and 'W' or 'E')
	return quad
end

function getNSEW(dx, dy)
	if (dx == nil) or (dy == nil) then return nil end
	local n = dy < 0
	local s = dy > 0
	local e = dx < 0
	local w = dx > 0
	return n,s,e,w
end

--[[
	Get the direction in radians that faces the given target's coordinates
--]]
function getFaceDirection(dx, dy)
	if (dx == nil) or (dy == nil) then return nil end
	
	local quad = getQuadrant(dx, dy)
	
	local theta = math.atan(math.abs(dy)/math.abs(dx))
	local phi = (math.pi * quadrants[quad][1]) + (theta * quadrants[quad][2])
	return phi
end

--[[
	Get the distance between the player and the given entity
--]]
function getDistance(name)
	local mobChar = windower.ffxi.get_mob_by_name(name)
	if mobChar ~= nil then
		return mobChar.distance
	end
	return nil
end

--[[
	Determine whether or not the given positions are different.
	If only one parameter is given, then it compares the given
	position with the result of calling getPosition().
--]]
function isMoving(pos1, pos2)
	if pos1 == nil then return nil end
	pos2 = pos2 and pos2 or getPosition()
	
	local dx = math.abs(pos1.x - pos2.x)
	local dy = math.abs(pos1.y - pos2.y)
	local dz = math.abs(pos1.z - pos2.z)
	local isMoving = ((dx + dy + dz) ~= 0)
	
	return isMoving
end

--[[
	Get the position of the entity with the given name, or own
	position if no name is given.
--]]
function getPosition(name)
	name = name and name or windower.ffxi.get_player().name
	local mobChar = windower.ffxi.get_mob_by_name(name)
	if mobChar ~= nil then
		local mobPos = {}
		mobPos.x = mobChar.x
		mobPos.y = mobChar.y
		mobPos.z = mobChar.z
		return Pos.new(mobPos)
	end
	return nil
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
