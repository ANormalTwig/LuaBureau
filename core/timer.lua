local loop = require("core.loop")
local os_difftime, os_time = os.difftime, os.time

local Emitter = require("core.emitter")

---@class Timer: Emitter
---@field looping boolean
---@field startTime number
---@field timeout number
---@field _done boolean
local Timer = {}
Timer.__index = Timer
setmetatable(Timer, Emitter)

--- Creates a new Timer
---@param timeout number
---@param looping boolean?
---@return Timer
function Timer:new(timeout, looping)
	local timer = setmetatable(getmetatable(self):new(), self)
	loop.add(timer)

	timer.looping = looping and true or false
	timer.timeout = timeout
	timer.startTime = os_time()

	return timer
end

--- Stops the timer from executing again
function Timer:stop()
	self._done = true
end

function Timer:poll()
	if os_difftime(os_time(), self.startTime) > self.timeout then
		self:emit("Timeout")
		if not self.looping then
			self._done = true
		end
	end
end

return Timer

