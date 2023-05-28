local math_sqrt = math.sqrt

---@class Vector3
---@field x number
---@field y number
---@field z number
local Vector3 = {}
Vector3.__index = Vector3

--- Create a new Vector3
---@param x number?
---@param y number?
---@param z number?
function Vector3:new(x, y, z)
	return setmetatable({x = x or 0, y = y or 0, z = z or 0}, self)
end

function Vector3.__add(a, b)
	return Vector3:new(a.x + b.x, a.y + b.y, a.z + b.z)
end

function Vector3.__sub(a, b)
	return Vector3:new(a.x - b.x, a.y - b.y, a.z - b.z)
end

function Vector3.__mul(a, b)
	return Vector3:new(a.x * b.x, a.y * b.y, a.z * b.z)
end

function Vector3.__div(a, b)
	return Vector3:new(a.x / b.x, a.y / b.y, a.z / b.z)
end

function Vector3:set(x, y, z)
	self.x = x
	self.y = y
	self.z = z
end

--- Gets the squared distance between two vectors
---@param v Vector3
function Vector3:getDistanceSqr(v)
	return (v.x - self.x)^2 + (v.y - self.y)^2 + (v.z - self.z)^2
end

--- Gets the distance between two vectors
---@param v Vector3
function Vector3:getDistance(v)
	return math_sqrt(self:getDistanceSqr(v))
end

return Vector3

