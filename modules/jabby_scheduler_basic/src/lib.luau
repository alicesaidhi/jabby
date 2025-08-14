local jabby_types = require(script.Parent.Parent.roblox_packages.jabby_types)
local lib = require(script.Parent.server.lib)

local interface: jabby_types.JabbyAppletInterface<{}> = {
	name = "Jabby Basic Scheduler",
	description = "Jabby Basic Scheduler",

	registered = function(self) lib(self) end,

	client = script.Parent.Parent.roblox_packages.jabby_scheduler,
}

return interface
