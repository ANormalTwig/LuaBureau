local Emitter = require("core.emitter")
local Matrix = require("core.matrix")
local Vector3 = require("core.vector3")

local protocol = require("bureau.protocol")

local string_format = string.format

---@class User: Emitter
---@field aura table<User, boolean>
---@field avatar string
---@field characterData string
---@field client Client
---@field id number
---@field name string
---@field position Vector3
---@field rotation Matrix
local User = {}
User.__index = User
setmetatable(User, Emitter)

--- Create new User
---@param id number
---@param client Client
---@return User user
function User:new(id, client)
	local user = getmetatable(self):new()

	user.avatar = ""
	user.aura = {}
	user.client = client
	user.id = id
	user.name = ""

	user.position = Vector3:new()
	user.rotation = Matrix:new()

	return setmetatable(user, self)
end

--- Add a user to the aura table
---@param other User
function User:addAura(other)
	self.aura[other] = true
	other.aura[self] = true

	self.client:send(string_format("%s%s",
		protocol.generalMessage({
			id1 = self.id,
			id2 = self.id,
			type = "SMSG_USER_JOINED",
		}, string_format("%s%s%s\0%s\0",
			protocol.fromU32(other.id),
			protocol.fromU32(other.id),
			self.avatar,
			self.name
		)),
		other.characterData and protocol.generalMessage({
			id1 = self.id,
			id2 = self.id,
			type = "MSG_COMMON",
		}, protocol.commonMessage({
			id = other.id,
			type = "CHARACTER_UPDATE",
			subtype = 1
		}, other.characterData)) or ""
	))

	other.client:send(string_format("%s%s",
		protocol.generalMessage({
			id1 = other.id,
			id2 = other.id,
			type = "SMSG_USER_JOINED",
		}, string_format("%s%s%s\0%s\0",
			protocol.fromU32(self.id),
			protocol.fromU32(self.id),
			self.avatar,
			self.name
		)),
		self.characterData and protocol.generalMessage({
			id1 = other.id,
			id2 = other.id,
			type = "MSG_COMMON",
		}, protocol.commonMessage({
			id = self.id,
			type = "CHARACTER_UPDATE",
			subtype = 1
		}, self.characterData)) or ""
	))
end

--- Remove a user from the aura table
---@param other User
function User:removeAura(other)
	self.aura[other] = nil
	other.aura[self] = nil

	if not self.client.closed then
		self.client:send(protocol.generalMessage({
			id1 = self.id,
			id2 = self.id,
			type = "SMSG_USER_LEFT",
		}, protocol.fromU32(other.id)))
	end
	other.client:send(protocol.generalMessage({
		id1 = other.id,
		id2 = other.id,
		type = "SMSG_USER_LEFT",
	}, protocol.fromU32(self.id)))
end

--- Check if a user is inside of another user's aura
---@param user User
---@return boolean
function User:checkAura(user)
	return self.position:getDistance(user.position) <= Config.aura_radius
end

return User

