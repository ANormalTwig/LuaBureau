local math_atan2, math_sqrt = math.atan2, math.sqrt

---@class Matrix
---@field m number[] array of 9 numbers for the 3x3 matrix
local Matrix = {}
Matrix.__index = Matrix

function Matrix:new()
	return setmetatable({
		m = {
			1, 0, 0,
			0, 1, 0,
			0, 0, 1,
		},
	}, self)
end

--- Update matrix array
---@param m number[] array of 9 numbers for the 3x3 matrix
function Matrix:set(m)
	self.m = m
end

--- Get rotation about the X axis
---@return number radians
function Matrix:getRotationX()
	local m = self.m
	return math_atan2(m[7], m[8])
end

--- Get rotation about the Y axis
---@return number radians
function Matrix:getRotationY()
	local m = self.m
	return math_atan2(-m[6], math_sqrt(m[7]^2 + m[8]^2))
end

--- Get rotation about the Z axis
---@return number radians
function Matrix:getRotationZ()
	local m = self.m
	return math_atan2(m[3], m[0])
end

function Matrix:scale(n)
	local m = self.m
	for i = 1, 9 do
		m[i] = m[i] * n
	end
end

return Matrix

