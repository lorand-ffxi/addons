local Pos = require('position')
local quadrants = {NW = {-1, 1}, SW = {1, -1}, NE = {0, -1}, SE = {0, 1}}
local compass = {N = -math.pi/2, S = math.pi/2, E = 0, W = math.pi, NW = -math.pi*3/4, NE = -math.pi*1/4, SW = math.pi*3/4, SE = math.pi*1/4}

function needToMove(targetName)
	if targetName ~= nil then
		local target = windower.ffxi.get_mob_by_name(targetName)
		if target ~= nil then
			return math.sqrt(target.distance) > followDist
		end
	end
	return false
end

function moveTowards(targetName)
	local target = windower.ffxi.get_mob_by_name(targetName)
	if target ~= nil then
		windower.ffxi.run(getDirRadian(getPosition(), getPosition(targetName)))
	end
end

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