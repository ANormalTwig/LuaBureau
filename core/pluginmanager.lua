local lfs = require("lfs")

local log = require("util.logger")

local plugins = {}
for file in lfs.dir("plugins") do
	file = "plugins/" .. file
	local ftype = lfs.attributes(file, "mode")
	if ftype == "file" and string.sub(file, #file - 3, #file) == ".lua" then
		local success, ret = pcall(dofile, file)
		if success then
			table.insert(plugins, ret)
		else
			log(0, "Couldn't load plugin %s", file)
		end
	elseif ftype == "directory" then
		if lfs.attributes(file .. "/init.lua", "mode") then
			local success, ret = pcall(dofile, file .. "/init.lua")
			if success and type(ret) == "function" then
				table.insert(plugins, ret)
			else
				log(0, "Couldn't load plugin %s", file)
			end
		end
	end
end

--- Loads all valid plugins in the 'plugin' folder on the specified bureau
---@param bureau Bureau
---@param wls WLS?
---@param worldName string?
return function(bureau, wls, worldName)
	for _, plugin in ipairs(plugins) do
		plugin(bureau, wls, worldName)
	end
end

