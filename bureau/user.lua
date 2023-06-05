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

	self:emit("EnteredAura", other)
	other:emit("EnteredAura", self)

	self.client:send(string_format("%s%s",
		protocol.generalMessage(
			self.id,
			self.id,
			"SMSG_USER_JOINED",

			string_format("%s%s%s\0%s\0",
				protocol.fromU32(other.id),
				protocol.fromU32(other.id),
				other.avatar,
				other.name
			)
		),
		other.characterData and protocol.generalMessage(
			self.id,
			self.id,
			"MSG_COMMON",

			protocol.commonMessage(
				other.id,
				"CHARACTER_UPDATE",
				1,
				other.characterData
			)
		) or ""
	))

	other.client:send(string_format("%s%s",
		protocol.generalMessage(
			other.id,
			other.id,
			"SMSG_USER_JOINED",

			string_format("%s%s%s\0%s\0",
				protocol.fromU32(self.id),
				protocol.fromU32(self.id),
				self.avatar,
				self.name
			)
		),
		self.characterData and protocol.generalMessage(
			other.id,
			other.id,
			"MSG_COMMON",

			protocol.commonMessage(
				self.id,
				"CHARACTER_UPDATE",
				1,
				self.characterData
			)
		) or ""
	))
end

--- Remove a user from the aura table
---@param other User
function User:removeAura(other)
	self.aura[other] = nil
	other.aura[self] = nil

	self:emit("LeftAura", other)
	other:emit("LeftAura", self)

	if not self.client.closed then
		self.client:send(protocol.generalMessage(
			self.id,
			self.id,
			"SMSG_USER_LEFT",

			protocol.fromU32(other.id)
		))
	end
	other.client:send(protocol.generalMessage(
		other.id,
		other.id,
		"SMSG_USER_LEFT",

		protocol.fromU32(self.id)
	))
end

--- Check if a user is inside of another user's aura
---@param user User
---@return boolean
function User:checkAura(user)
	return self.position:getDistance(user.position) <= Config.aura_radius
end

return User

