local jabby_types = require(script.Parent.Parent.roblox_packages.jabby_types)
local lib = require(script.Parent.server.lib)

local interface: jabby_types.JabbyAppletInterface<nil> = {
	name = "alicesaidhi/jabby-home",
	description = "Primary widget for jabby.",

	registered = function(self)
		lib(self)
	end,

	client = script.Parent.client.lib
}

return interface