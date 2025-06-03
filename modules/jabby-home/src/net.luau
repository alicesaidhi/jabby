local gt = require(script.Parent.Parent.roblox_packages.gt)
local jabby_net = require(script.Parent.Parent.roblox_packages.jabby_net)

local NAMESPACE = "alicesaidhi/jabby-home"

local NETWORK_LAYER = {

	get_registered_applets = jabby_net.function_create(
		NAMESPACE, "get_registered_applets",
		gt.none(),
		gt.table {
			socket = gt.number(),

			applets = gt.array {
				name = gt.string(),
				description = gt.string(),
				id = gt.number(),
				client = gt.isA.ModuleScript()
			}
		}
	),

	add_registered_applet = jabby_net.socket_create(
		NAMESPACE, "add_registered_applet",
		gt.table {
			name = gt.string(),
			description = gt.string(),
			id = gt.number(),
			client = gt.isA.ModuleScript()
		}
	)

}

return NETWORK_LAYER