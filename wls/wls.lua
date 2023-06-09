local loadPlugins = require("core.pluginmanager")
local log = require("util.logger")
local string_format = string.format

local Bureau = require("bureau.bureau")
local Pool = require("core.pool")
local Server = require("core.server")
local Timer = require("core.timer")

---@class WLS: Server
---@field bureaus table<string, table<Bureau, boolean>>
---@field pool Pool
---@field totalBureaus number
local WLS = {}
WLS.__index = WLS
setmetatable(WLS, Server)

--- Create a new WLS.
---@return WLS
function WLS:new()
	local wls = setmetatable(getmetatable(self):new(), self)

	wls.bureaus = {}
	wls.totalBureaus = 0

	wls.pool = Pool:new(Config.max_bureaus)

	wls:on("Connect", function(client)
		---@cast client Client

		local timer = Timer:new(10)
		timer:on("Timeout", function()
			client:close()
		end)

		client:on("Data", function(data)
			local args = {}
			for arg in string.gmatch(data, "[^,]+") do
				table.insert(args, arg)
			end

			if args[1] ~= "f" then
				client:close()
				return
			end

			local bureau = wls:getBureau(args[3])
			if not bureau then
				client:close()
				return
			end

			client:send(string_format("f,0,%s,%d\0", Config.bureau_address, bureau.port))
		end)
	end)

	return wls
end

--- Gets a currently active or starts a new bureau with the specified world name
---@param worldName string
---@return Bureau|nil
function WLS:getBureau(worldName)
	if not self.bureaus[worldName] then
		log(2, "Attempting to generate a new Buearu.")
		return self:newBureau(worldName)
	end

	for bureau in pairs(self.bureaus[worldName]) do
		if bureau:getUserCount() < Config.max_users then
			return bureau
		end
	end

	log(2, "Attempting to generate a new Buearu.")
	return self:newBureau(worldName)
end

--- Attempt to generate a new bureau under the worldname
---@private
---@param worldName string
---@return Bureau|nil
function WLS:newBureau(worldName)
	local bureau = Bureau:new(Config.max_users)
	self.totalBureaus = self.totalBureaus + 1

	loadPlugins(bureau, self, worldName)

	local id = self.pool:getID()
	if not id then
		log(2, "Can't generate new Bureau, max Bureaus reached.")
		return
	end

	bureau:listen(Config.port + id)
	if not self.bureaus[worldName] then
		self.bureaus[worldName] = {}
	end
	self.bureaus[worldName][bureau] = true
	bureau:on("Close", function()
		self.pool:freeID(id)
		self.bureaus[worldName][bureau] = nil
		self.totalBureaus = self.totalBureaus - 1
	end)

	local timer = Timer:new(10)

	bureau:on("UserLeft", function()
		if bureau:getUserCount() == 0 then
			bureau:close()
		end
	end)

	bureau:on("UserJoined", function()
		timer:stop()
	end)

	timer:on("Timeout", function()
		log(2, "Bureau closed due to the lack of any user connection.")
		bureau:close()
	end)

	return bureau
end

return WLS

