local ecr = require(script.Parent.Parent.roblox_packages.ecr)
local jabby_types = require(script.Parent.Parent.roblox_packages.jabby_types)
local lib = require(script.Parent.server.lib)

local interface: jabby_types.JabbyAppletInterface<{
	world: ecr.Registry,
	components: {
		[string]: unknown
	}
}> = {
	name = "Jabby ECR Registry",
	description = "ECR Registry",

	registered = function(self)
		lib(self)
	end,

	client = script.Parent.Parent.roblox_packages.jabby_ecs_registry
}

return interface