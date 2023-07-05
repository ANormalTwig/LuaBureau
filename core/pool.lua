local math_max = math.max

---@class Pool
---@field count number Number of IDs the pool can manage.
---@field min number Lowest value the pool will return.
---@field used table<number, true|nil>
---@field index number Position the Pool will check before trying the next ID.
local Pool = {}
Pool.__index = Pool

--- Create a new Pool.
---@param count number
---@param min number? the minimum value to be returned
---@return Pool
function Pool:new(count, min)
	return setmetatable({
		used = {},
		count = count,
		min = min or 1,
		index = min or 1,
	}, self)
end

--- Get an ID from the pool
---@return number|nil id Returns the id or nil if there are none left.
function Pool:getID()
	for _ = 1, self.count do
		if not self.used[self.index] then
			self.used[self.index] = true
			return self.index
		end
		self.index = math_max(self.index % (self.min + self.count - 1), self.min - 1) + 1
	end
end

--- Free an ID to the pool
---@param id number
function Pool:freeID(id)
	self.used[id] = nil
end

return Pool

