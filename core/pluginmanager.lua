local lfs = require("lfs")

local log = require("util.logger")

local plugins = {}
for file in lfs.dir("./plugins") do
	local type = lfs.attributes(file, "mode")
	if type == "file" then
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

return function(bureau)
	for _, plugin in ipairs(plugins) do
		plugin(bureau)
	end
end

