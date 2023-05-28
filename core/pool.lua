---@class Pool
---@field max number Max amount of IDs the pool can manage.
---@field used table<number, true|nil>
---@field index number Position the Pool will check before trying the next ID.
local Pool = {}
Pool.__index = Pool

--- Create a new Pool.
---@param max number
---@return Pool
function Pool:new(max)
	return setmetatable({
		used = {},
		max = max,
		index = 1,
	}, self)
end

function Pool:getID()
	for _ = 1, self.max do
		if not self.used[self.index] then
			self.used[self.index] = true
			return self.index
		end
		self.index = (self.index % self.max) + 1
	end
	return false
end

function Pool:freeID(id)
	self.used[id] = nil
end

return Pool

