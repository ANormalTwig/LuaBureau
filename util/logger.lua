local string_format = string.format

--- Logs a message depending on the set verbosity level. (-v <n>, --verbose <n>)
---@param level number Verbosity level.
---@param format string Message to log
---@param ... any
return function(level, format, ...)
	if Config.verbosity >= level then print("[LOG]", string_format(format, ...)) end
end

