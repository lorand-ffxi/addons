local Queue = {}

function Queue.new()
	local self = {q={}}
	return setmetatable(self, {__index = Queue})
end

function Queue:pop()
	return table.remove(self.q, 1)
end

function Queue:peekNext()
	return self.q[1]
end

function Queue:peekLast()
	return self.q[#self.q]
end

function Queue:append( el)
	assert(el ~= nil)
	table.insert(self.q, el)
end

function Queue:asTable()
	return self.q
end

function Queue:size()
	return #self.q
end

return Queue