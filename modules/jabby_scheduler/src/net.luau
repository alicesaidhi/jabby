local gt = require(script.Parent.Parent.roblox_packages.gt)
local jabby_net = require(script.Parent.Parent.roblox_packages.jabby_net)

local NAMESPACE = "alicesaidhi/jabby-scheduler"

local NETWORK_LAYER = {

	watch_scheduler = jabby_net.function_create(
		NAMESPACE,
		"watch_scheduler",
		gt.none(),
		gt.table {
			name = gt.string(),

			update_system_data = gt.number(),
			remove_system = gt.number(),
			update_system_frame = gt.number(),
		}
	),

	update_system_state = jabby_net.socket_create(
		NAMESPACE,
		"update_system_state",
		gt.table {
			id = gt.number(),

			name = gt.opt(gt.string()),
			phase = gt.opt(gt.string()),
			paused = gt.opt(gt.bool()),
		}
	),

	remove_system = jabby_net.socket_create(
		NAMESPACE,
		"remove_system",
		gt.table {
			id = gt.number(),
		}
	),

	update_system_frame = jabby_net.socket_create(
		NAMESPACE,
		"update_system_frame",
		-- takes in a:
		-- u16 - system id
		-- u32 - system frame
		-- f32 - time
		-- f32 - allocations
		--
		gt.buffer()
	),
}

return NETWORK_LAYER
