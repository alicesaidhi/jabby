local gt = require(script.Parent.Parent.roblox_packages.gt)
local jabby_net = require(script.Parent.Parent.roblox_packages.jabby_net)

local NAMESPACE = "alicesaidhi/jabby-home"

local NETWORK_LAYER = {

	get_registered_applets = jabby_net.function_create(
		NAMESPACE,
		"get_registered_applets",
		gt.none(),
		gt.array {
			name = gt.string(),
			description = gt.string(),
			id = gt.number(),
			client = gt.isA.ModuleScript(),
		}
	),

	get_performance_socket = jabby_net.function_create(
		NAMESPACE,
		"get_performance_socket",
		gt.none(),
		gt.table {
			socket = gt.number(),
		}
	),
	communicate_frame_time = jabby_net.socket_create(
		NAMESPACE,
		"communicate_frame_time",
		gt.buffer()
	),
}

return NETWORK_LAYER
