local log = require("util.logger")
local protocol = require("bureau.protocol")

local Pool = require("core.pool")
local Server = require("core.server")
local User = require("bureau.user")

local string_byte, string_format, string_match, string_rep, string_sub = string.byte,  string.format, string.match, string.rep, string.sub

local function hexify(str)
	local chars = {string_byte(str, 1, #str)}
	return string.format(string_rep("%02x ", #chars), unpack(chars))
end

---@class Bureau: Server
---@field users table<number, User>
---@field serverid number
---@field pool Pool
local Bureau = {}
Bureau.__index = Bureau
setmetatable(Bureau, Server)

--- Creates a new Bureau object.
---@param max number? Max amount of users that can be connected.
function Bureau:new(max)
	local bureau = getmetatable(self):new()
	setmetatable(bureau, self)

	bureau.users = {}
	bureau.pool = Pool:new((max or 0xFF) + 1)

	local serverid = bureau.pool:getID()
	if not serverid then error("Failed to assign an ID to the server.") end
	bureau.serverid = serverid

	bureau:on("Connect", function(client)
		---@cast client Client

		---@type User
		local user

		client:on("Close", function()
			if not user then return end

			for other in pairs(user.aura) do
				user:removeAura(other)
			end

			bureau.pool:freeID(user.id)
			bureau.users[user.id] = nil

			bureau:emit("UserLeft", user)

			local userCount = bureau:getUserCount()
			---@diagnostic disable-next-line: redefined-local
			bureau:sendAll(function(user)
				return protocol.generalMessage(
					0, user.id,
					"SMSG_USER_COUNT",

					protocol.fromU8(1) .. protocol.fromU32(userCount)
				)
			end)
		end)

		client:on("Data", function(data)
			if not user then
				if not data == "hello\1\1" then
					client:close()
					return
				end

				local id = bureau.pool:getID()
				if not id then
					client:close()
					return
				end

				local helloResponse = string_format("hello\0%s%s", protocol.fromU32(id), protocol.fromU32(id))
				client:send(helloResponse)
				user = User:new(id, client)
				bureau.users[user.id] = user

				bureau:emit("UserJoined", user)

				if MOTDMessage then
					bureau:sendMessage(user, MOTDMessage)
				end

				return
			end

			-- https://github.com/LeadRDRK/OpenBureau/blob/main/docs/Protocol.md
			-- OpenBureau documentation is wrong? all numbers seem to be big endian after light testing and sectionType is an 8bit uint
			log(3, "Got: %s", hexify(data))
			while #data >= 17 do
				local sectionType = protocol.getU8(data, 1)
				local id = protocol.getU32(data, 2)
				if id ~= user.id then
					log(2, "ID Mismatch from %s(%d).", user.name, user.id)
					return
				end
				local messageSize
				if sectionType == 0 then
					messageSize = 17 + protocol.getU32(data, 14)
					bureau:handleGeneralMessage(string_sub(data, 1, messageSize), user)
				elseif sectionType == 2 then
					messageSize = 27
					bureau:handlePositionUpdate(string_sub(data, 1, messageSize), user)
				else
					log(0, "Got invalid Section Type from %s(%d).", user.name, user.id)
					return
				end

				data = string_sub(data, messageSize + 1)
			end
		end)
	end)

	return bureau
end

--- Sends a chat message to the specified user.
---@param user User
---@param message string
---@param prependServer boolean Whether to prepend '[Server]' to the beginning of the message.
function Bureau:sendMessage(user, message, prependServer)
	user.client:send(string_format("%s%s%s",
		protocol.generalMessage(
			user.id, user.id,
			"SMSG_USER_JOINED",

			string_format("%s%s%s\0%s\0",
				protocol.fromU32(self.serverid),
				protocol.fromU32(self.serverid),
				"avtwrl/01cat.wrl",
				"Server"
			)
		),

		protocol.generalMessage(
			user.id, user.id,
			"MSG_COMMON",

			protocol.commonMessage(
				self.serverid,
				"CHAT_SEND",
				0,

				prependServer and string_format("[Server] %s\0", message) or message .. "\0"
			)
		),

		protocol.generalMessage(
			user.id, user.id,
			"SMSG_USER_LEFT",

			protocol.fromU32(self.serverid)
		)
	))
end

--- Get the current number of users connected to the Bureau.
---@return number users
function Bureau:getUserCount()
	local userCount = 0
	for _, _ in pairs(self.users) do
		userCount = userCount + 1
	end
	return userCount
end

--- Broadcast a message to every client.
---@param cb fun(user: User): string|nil
function Bureau:sendAll(cb)
	for _, user in pairs(self.users) do
		local msg = cb(user)
		if msg then
			user.client:send(msg)
		end
	end
end

---@type table<number, fun(bureau: Bureau, user: User, data: string, subtype: number): string|nil>
local commonMessages = {
	[protocol.commonTypes.APPL_SPECIFIC] = function(_, user, data, subtype)
		return protocol.commonMessage(
			user.id,
			"APPL_SPECIFIC",
			subtype,

			string_sub(data, 27)
		)
	end,

	[protocol.commonTypes.CHAT_SEND] = function(bureau, user, data, subtype)
		local content = string_sub(data, 27)
		local message = string_sub(content, 1, #content - 1) -- Trunicate null character

		-- Don't send empty messages.
		if #string.match(string_sub(message, #user.name + 3), "^%s*(.-)%s*$") == 0 then return end

		-- If a plugin returns true during their event callback, suppress the message.
		if user:emit("ChatMessage", string_sub(message, 1, #message - 1)) then return end

		return protocol.commonMessage(
			user.id,
			"CHAT_SEND",
			subtype,

			content
		)
	end,

	[protocol.commonTypes.NAME_CHANGE] = function(_, user, data, subtype)
		local name = string_sub(data, 27)
		local username = string_sub(name, 1, #name - 1)	-- Trunicate null character

		local oldName = user.name
		user.name = username
		user:emit("NameChange", username, oldName)

		return protocol.commonMessage(
			user.id,
			"NAME_CHANGE",
			subtype,

			name
		)
	end,

	[protocol.commonTypes.AVATAR_CHANGE] = function(_, user, data, subtype)
		local avatar = string_sub(data, 27)
		local userAvatar = string_sub(avatar, 1, #avatar - 1)	-- Trunicate null character

		local oldAvatar = user.avatar
		user.avatar = userAvatar
		user:emit("AvatarChange", userAvatar, oldAvatar)

		return protocol.commonMessage(
			user.id,
			"AVATAR_CHANGE",
			subtype,

			avatar
		)
	end,

	[protocol.commonTypes.TRANSFORM_UPDATE] = function(_, user, data, subtype)
		local m = {}
		for i = 0, 8 do
			m[i + 1] = protocol.get32float(data, 27 + i * 4)
		end
		user.rotation:set(m)
		user:emit("TransformUpdate")

		user.position:set(
			protocol.get32float(data, 63),
			protocol.get32float(data, 67),
			protocol.get32float(data, 71)
		)
		user:emit("PositionUpdate")

		return protocol.commonMessage(
			user.id,
			"TRANSFORM_UPDATE",
			subtype,

			string_sub(data, 27)
		)
	end,

	[protocol.commonTypes.CHARACTER_UPDATE] = function(_, user, data, subtype)
		local characterData = string_sub(data, 27)
		user.characterData = characterData

		local sleepStatus = string_match(characterData, "^sleep:(.) ")
		if not sleepStatus then return end

		user:emit("CharacterUpdate", {
			sleep = sleepStatus == "0"
		})

		return protocol.commonMessage(
			user.id,
			"CHARACTER_UPDATE",
			subtype,

			characterData
		)
	end,

	[protocol.commonTypes.VOICE_STATE] = function() end,
	[protocol.commonTypes.UNNAMED_1] = function() end,

	[protocol.commonTypes.PRIVATE_CHAT] = function(bureau, user, data, subtype)
		local sender = bureau.users[protocol.getU32(data, 18)]
		local recipient = bureau.users[protocol.getU32(data, 27)]

		if not sender or not recipient then return end
		local message = string_sub(data, 31)

		bureau:emit("PrivateMessage", user, recipient, message)
		user:emit("PrivateMessage", recipient, message)

		return protocol.commonMessage(
			user.id,
			"PRIVATE_CHAT",
			subtype,

			string_format("%s%s",
				protocol.fromU32(sender.id),
				message
			)
		)
	end,
}

---@type table<number, fun(bureau: Bureau, user: User, data: string)>
local generalFunctions = {
	[protocol.opcodes.CMSG_NEW_USER] = function(bureau, user, data)
		local name = protocol.getString(data, 18)
		local avatar = protocol.getString(data, 19 + #name)

		user.name = name
		user.avatar = avatar

		log(1, "%s has Joined.", name)

		local userJoinedContent = string_format("%s%s%s\0%s\0", protocol.fromU32(user.id), protocol.fromU32(user.id), avatar, name)
		user.client:send(string_format("%s%s%s%s",
			protocol.generalMessage(
				0, user.id,
				"SMSG_CLIENT_ID",

				protocol.fromU32(user.id)
			),

			protocol.generalMessage(
				user.id, user.id,
				"SMSG_UNNAMED_1",

				protocol.fromU32(1) .. protocol.fromU8(1)
			),

			protocol.generalMessage(
				user.id, user.id,
				"SMSG_USER_JOINED",

				userJoinedContent
			),

			protocol.generalMessage(
				user.id, user.id,
				"SMSG_BROADCAST_ID",

				protocol.fromU32(user.id)
			)
		))

		local userCount = bureau:getUserCount()
		---@diagnostic disable-next-line: redefined-local
		bureau:sendAll(function(user)
			return protocol.generalMessage(
				0, user.id,
				"SMSG_USER_COUNT",

				protocol.fromU8(1) .. protocol.fromU32(userCount)
			)
		end)
	end,

	[protocol.opcodes.MSG_COMMON] = function(bureau, user, data)
		local subtype = protocol.getU8(data, 26)
		if subtype < 0 or subtype > 4 then
			log(2, "Invalid Message Common subtype from %s(%d)", user.name, user.id)
			return
		end

		local type = protocol.getU32(data, 22)
		local func = commonMessages[type]
		if not func then
			log(2, "%s(%d) Sent an invalid MSG_COMMON type. (%d)", user.name, user.id, type)
			return
		end
		local msg = func(bureau, user, data, subtype)
		if msg then
			if subtype == 0 or subtype == 1 then
				bureau:sendAll(function(other)
					if user == other then return end
					return protocol.generalMessage(
						other.id, other.id,
						"MSG_COMMON",

						msg
					)
				end)
			elseif subtype == 2 or subtype == 3 then
				local id = protocol.getU32(data, 18)
				local target = bureau.users[id]
				if target then
					target.client:send(protocol.generalMessage(
						id, id,
						"MSG_COMMON",

						msg
					))
				end
			end
		end
	end,

	[protocol.opcodes.CMSG_STATE_CHANGE] = function(_, user, data)
		local state = protocol.getU8(data, 18)
		user:emit("StateChange", state)
		log(2, "%s(%d)'s state is now %s", user.name, user.id, state)
	end,
}

--- Internal use only.
---@param data string
---@param user User
---@protected
function Bureau:handleGeneralMessage(data, user)
	local func = generalFunctions[protocol.getU32(data, 10)]
	if not func then log(2, "Unhandled opcode %d", protocol.getU32(data, 10)) return end
	func(self, user, data)
end

--- Internal use only.
---@param data string
---@param user User
---@protected
function Bureau:handlePositionUpdate(data, user)
	user.position:set(
		protocol.get32float(data, 14),
		protocol.get32float(data, 18),
		protocol.get32float(data, 22)
	)

	user:emit("PositionUpdate")

	self:sendAll(function(other)
		if user == other then return end
		local inAura = user:checkAura(other)

		if inAura then
			if not user.aura[other] then
				log(2, "%s(%d) entered %s(%d)'s Aura.", user.name, user.id, other.name, other.id)
				user:addAura(other)
			end

			other.client:send(protocol.positionUpdate(user, other))
		elseif user.aura[other] then
			log(2, "%s(%d) left %s(%d)'s Aura.", user.name, user.id, other.name, other.id)
			user:removeAura(other)
		end
	end)
end

return Bureau

