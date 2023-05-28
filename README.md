# LuaBureau

<img src="https://raw.githubusercontent.com/ANormalTwig/LuaBureau/main/icon.png" width="200" height="200">

An implementation of the [VSCP Protocol](https://github.com/LeadRDRK/OpenBureau/blob/main/docs/Protocol.md) in Lua with [luasocket](https://github.com/lunarmodules/luasocket).

## Dependencies

To be installed with luarocks or otherwise.

[luasocket](https://github.com/lunarmodules/luasocket)

[luafilesystem](https://github.com/lunarmodules/luafilesystem)

## Usage

```bash
$ luajit main.lua [options]
```

## Options

| Option | Purpose | Default |
|--------|---------|---------|
| -c --config | Specify a config file (Discards all other comand-line arguments if set | |
| -p --port | Specify the port for the server to run on. | 5126 |
| -r --aura-radius | Specify the distance at which users can see each other | 100 |
| -v --verbose | Set verbosity level | 0 |
| -w --wls | Run in WLS mode (Not Implemented) 0 = false, 1 = true | 0 |

# Config File

Config file is a list of key=value entries

```
port=5126
aura_radius=100
verbosity=0
wls=0
```
