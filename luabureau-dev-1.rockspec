package = "LuaBureau"
version = "dev-1"
source = {
   url = "*** please add URL for source tarball, zip or repository here ***"
}
description = {
   homepage = "*** please enter a project homepage ***",
   license = "*** please specify a license ***"
}
build = {
   type = "builtin",
   modules = {
      ["core.emitter"] = "core/emitter.lua",
      main = "main.lua",
      ["util.argparse"] = "util/argparse.lua",
      ["util.config"] = "util/config.lua",
      ["util.logger"] = "util/logger.lua",
      ["util.printtable"] = "util/printtable.lua"
   }
}
