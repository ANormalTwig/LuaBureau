---@class Loop
---@field children table<number, { poll: function, _done: boolean }>
---@field _done boolean
Loop = {}
Loop.__index = Loop

function Loop:new()
	return setmetatable({children = {}}, self)
end

--- Add an object to be polled
---@param object { poll: function, _done: boolean }
function Loop:add(object)
	if not object.poll then return end
	if object == self then error("Cannot add a loop to its own loop.") end
	table.insert(self.children, object)
end

--- Iterates a single time over the loop's childrens' poll methods.
function Loop:poll()
	if #self.children == 0 then
		self._done = true
		return
	end

	for i, object in ipairs(self.children) do
		if object._done then
			table.remove(self.children, i)
		else
			object:poll()
		end
	end
end

--- Run the loop until it or it's children are done.
function Loop:run()
	while not self._done do
		self:poll()
	end
end

return Loop

