local lfs = require("lfs")

local log = require("util.logger")

local plugins = {}
for file in lfs.dir("plugins") do
	file = "plugins/" .. file
	local type = lfs.attributes(file, "mode")
	if type == "file" and string.sub(file, #file - 3, #file) == ".lua" then
		local success, ret = pcall(dofile, file)
		if success then
			table.insert(plugins, ret)
		else
			log(0, "Couldn't load plugin %s", file)
		end
	elseif type == "directory" then
		if lfs.attributes(file .. "/init.lua", "mode") then
			local success, ret = pcall(dofile, file .. "/init.lua")
			if success then
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
return function(bureau, wls)
	for _, plugin in ipairs(plugins) do
		plugin(bureau, wls)
	end
end

