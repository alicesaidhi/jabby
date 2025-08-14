local jabby_types = require(script.Parent.Parent.roblox_packages.jabby_types)
local jecs = require(script.Parent.Parent.roblox_packages.jecs)
local lib = require(script.Parent.server.lib)

local interface: jabby_types.JabbyAppletInterface<{
	world: jecs.World,
}> = {
	name = "Jabby JECS Registry",
	description = "JECS Registry",

	registered = function(self) lib(self) end,

	client = script.Parent.Parent.roblox_packages.jabby_ecs_registry,
}

return interface
