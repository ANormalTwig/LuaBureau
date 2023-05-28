---@class Loop
---@field children table<number, { poll: function, _done: boolean }>
Loop = {}
Loop.__index = Loop

function Loop:new()
	return setmetatable({children = {}}, self)
end

--- Add an object to be polled
---@param object { poll: function, _done: boolean }
function Loop:add(object)
	if not object.poll then return end
	table.insert(self.children, object)
end

function Loop:run()
	while #self.children > 0 do
		for i, object in ipairs(self.children) do
			if object._done then
				table.remove(self.children, i)
			else
				object:poll()
			end
		end
	end
end

return Loop

