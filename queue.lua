
local Queue = {}
Queue.__index = Queue

setmetatable(Queue, {
	__call = function(cls, ...)
		return cls.new(...)
	end
})

function Queue.new()
	local self = setmetatable({}, Queue)
	self.q = {}
	return self
end

function Queue:add(item)
	local i = #self.q
	self.q[i+1] = item
end

function Queue:getNext()
	local item = self.q[1]
	self:advance()
	return item
end

function Queue:advance()
	local i = 1
	while i <= #self.q do
		self.q[i] = self.q[i+1]		--The element one past the last index will always be nil
		i = i + 1
	end
end

function Queue:size()
	return #self.q
end

function Queue:getFirst()
	return self.q[1]
end

function Queue:getLast()
	return self.q[#self.q]
end