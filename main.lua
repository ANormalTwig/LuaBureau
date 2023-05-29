assert(jit, "This project is intended to be ran with LuaJIT")

local argparse = require("util.argparse")

local parser = argparse("script")
parser:option("-a --bureau-address", "Address of the bureau used in the WLS server.")
	:default("127.0.0.1")
parser:option("-b --max-bureaus", "Max bureaus.")
	:convert(tonumber)
	:default(10)
parser:option("-c --config", "Config file. (Discards all other command-line arguments if set)")
parser:option("-u --max-users", "Max users of a bureau.")
	:convert(tonumber)
	:default(0xFF)
parser:option("-p --port", "Port number.")
	:convert(tonumber)
	:default(5126)
parser:option("-r --aura-radius", "Aura radius.")
	:convert(tonumber)
	:default(100)
parser:option("-v --verbose", "Verbosity level.")
	:convert(tonumber)
	:default(0)
	:target("verbosity")
parser:option("-w --wls", "Run in WLS mode.")
	:args(0)
	:default(false)

local args = parser:parse()
if args.config then
	local file = assert(io.open(args.config, "r"), "Config file not found.")
	local config = file:read("*a")
	Config = require("util.config")(config, {
		aura_radius = {"number", 100},
		bureau_address = {"string", "127.0.0.1"},
		max_bureaus = {"number", 10},
		max_users = {"number", 0xFF},
		port = {"number", 5126},
		verbosity = {"number", 0},
		wls = {"boolean", false},
	})
	file:close()
else
	Config = args
end

require("util.printtable")(Config)

if Config.wls then
	local wls = require("wls.wls"):new()
	wls:listen(Config.port)
	wls:run()

	return
end

local bureau = require("bureau.bureau"):new(Config.max_users)
require("core.pluginmanager")(bureau)
bureau:listen(Config.port)
bureau:run()

