
local Queue = {}

function Queue:pop()
	return table.remove(this.q, 1)
end

function Queue:peek()
	return this.q[1]
end

function Queue.append(el)
	assert(el ~= nil)
	table.insert(this.q, el)
end

function Queue.asTable()
	return this.q
end

function Queue.new()
	local this = {q={}}
	return setmetatable(this, {__index = Queue})
end