local bit_band, bit_rshift = bit.band, bit.rshift
local math_floor = math.floor
local string_byte, string_char, string_format, string_match = string.byte, string.char, string.format, string.match

local function getU8(str, i)
	return string_byte(str, i)
end

local function getU16(str, i)
	local a, b = string_byte(str, i, i + 1)
	return  a * 0x100 + b
end

local function getU32(str, i)
	local a, b, c, d = string_byte(str, i, i + 3)
	return  a * 0x1000000 + b * 0x10000 + c * 0x100 + d
end

local function get8(str, i)
	local n = getU8(str, i)
	if n >= 0x80 then return n - 0x100 end
	return n
end

local function get16(str, i)
	local n = getU16(str, i)
	if n >= 0x8000 then return n - 0x10000 end
	return n
end

local function get32(str, i)
	local n = getU32(str, i)
	if n >= 0x80000000 then return n - 0x100000000 end
	return n
end

local function get32float(str, i)
	local n = getU32(str, i)
	if n >= 0x80000000 then return (n - 0x100000000) / 0xFFFF end
	return n / 0xFFFF
end

local fromU8 = string_char

local function fromU16(n)
	return string_char(
		bit_band(n, 0xFF00) / 0x100,
		bit_band(n, 0xFF)
	)
end

local function from32(n)
	if n < 0 then n = n - 0x100000000 end
	return string_char(bit_rshift(n, 24) % 0x100, bit_rshift(n, 16) % 0x100, bit_rshift(n, 8) % 0x100, n % 0x100)
end

local fromU32 = from32

local function from32float(n)
	n = math_floor(n * 0xFFFF)
	if n < 0 then n = n - 0x100000000 end
	return string_char(bit_rshift(n, 24) % 0x100, bit_rshift(n, 16) % 0x100, bit_rshift(n, 8) % 0x100, n % 0x100)
end

local function getString(str, i)
	return string_match(str, "(.-)%z", i)
end

---@enum states
local states = {
	NOT_CONNECTED = 0,
	CONNECTING = 1,
	CONNECTED = 2,
	DISCONNECTING = 3,
	ACTIVE = 4,
	SLEEP = 5,
}

---@enum opcodes
local opcodes = {
	CMSG_NEW_USER = 0,
	SMSG_CLIENT_ID = 1,
	SMSG_USER_JOINED = 2,
	SMSG_USER_LEFT = 3,
	SMSG_BROADCAST_ID = 4,
	MSG_COMMON = 6,
	CMSG_STATE_CHANGE = 7,
	SMSG_UNNAMED_1 = 8,
	SMSG_USER_COUNT = 11,
}

---@enum commonTypes
local commonTypes = {
	TRANSFORM_UPDATE = 0x00000002,
	CHAT_SEND = 0x00000009,
	CHARACTER_UPDATE = 0x0000000C,
	NAME_CHANGE = 0x0000000D,
	AVATAR_CHANGE = 0x0000000E,
	PRIVATE_CHAT = 0x00000000F,
	UNNAMED_1 = 0x0000000010,
	VOICE_STATE = 0x00000012,
	APPL_SPECIFIC = 0x00002710,
}

--- Helper function to make a general message
---@param id1 number
---@param id2 number
---@param type string
---@param content string
---@return string
local function generalMessage(id1, id2, type, content)
	return string_format("%s%s%s%s%s%s",
		"\0",
		fromU32(id1),
		fromU32(id2),
		fromU32(opcodes[type]),
		fromU32(#content),
		content
	)
end

--- Helper function to make common messages
---@param id number
---@param type string
---@param subtype number
---@param content string
local function commonMessage(id, type, subtype, content)
	return string_format("%s%s%s%s",
		fromU32(id),
		fromU32(commonTypes[type]),
		fromU8(subtype),
		content
	)
end

--- Helper function to make a position update message
---@param user User
---@param other User
---@return string
local function positionUpdate(user, other)
	return string_format("%s%s%s%s%s%s%s%s", 
		"\2",
		fromU32(other.id),
		fromU32(other.id),
		fromU32(user.id),
		from32(math.floor(user.position.x * 0xFFFF)),
		from32(math.floor(user.position.y * 0xFFFF)),
		from32(math.floor(user.position.z * 0xFFFF)),
		fromU16(0x100)
	)
end

return {
	states = states,
	opcodes = opcodes,
	commonTypes = commonTypes,

	generalMessage = generalMessage,
	commonMessage = commonMessage,
	positionUpdate = positionUpdate,

	getU8 = getU8,
	getU16 = getU16,
	getU32 = getU32,

	fromU8 = fromU8,
	fromU16 = fromU16,
	fromU32 = fromU32,

	get8 = get8,
	get16 = get16,
	get32 = get32,

	get32float = get32float,
	from32float = from32float,

	from32 = from32,

	getString = getString,
}

