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

local string_format = string.format
function Vector3:__tostring()
	return string_format("[%f, %f, %f]", self.x, self.y, self.z)
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

--- Adds v to self.
---@param v Vector3
function Vector3:add(v)
	self.x = self.x + v.x
	self.y = self.y + v.y
	self.z = self.z + v.z
end

--- Subtracts v from self.
---@param v Vector3
function Vector3:sub(v)
	self.x = self.x - v.x
	self.y = self.y - v.y
	self.z = self.z - v.z
end

--- Multipies self by v.
---@param v Vector3
function Vector3:mul(v)
	self.x = self.x * v.x
	self.y = self.y * v.y
	self.z = self.z * v.z
end

--- Divides self by v.
---@param v Vector3
function Vector3:div(v)
	self.x = self.x / v.x
	self.y = self.y / v.y
	self.z = self.z / v.z
end

--- Set the x, y, and z of the vector.
function Vector3:set(x, y, z)
	self.x = x
	self.y = y
	self.z = z
end

--- Returns the dot product of two vectors (cosine of the angle between two vectors multiplied their length).
---@return number dot Dot product.
function Vector3:dot(v)
	return self.x * v.x + self.y * v.y + self.z * v.z
end

--- Gets the squared distance between two vectors.
---@param v Vector3
---@return number distance Distance squared.
function Vector3:getDistanceSqr(v)
	return (v.x - self.x)^2 + (v.y - self.y)^2 + (v.z - self.z)^2
end

--- Gets the distance between two vectors.
---@param v Vector3
---@return number distance Distance.
function Vector3:getDistance(v)
	return math_sqrt((v.x - self.x)^2 + (v.y - self.y)^2 + (v.z - self.z)^2)
end

--- Returns the length of the vector squared.
---@return number length Squared length.
function Vector3:getLengthSqr()
	return self.x^2 + self.y^2 + self.z^2
end

--- Returns the length of the vector.
---@return number length Length.
function Vector3:getLength()
	return math_sqrt(self.x^2 + self.y^2 + self.z^2)
end

--- Normalizes a vector.
function Vector3:normalize()
	local n = math_sqrt(self.x^2 + self.y^2 + self.z^2)
	self.x = self.x / n
	self.y = self.y / n
	self.z = self.z / n
end

--- Returns the vector normalized.
---@return Vector3 normal
function Vector3:getNormalized()
	local n = math_sqrt(self.x^2 + self.y^2 + self.z^2)
	return Vector3:new(self.x / n, self.y / n, self.z / n)
end

return Vector3

