local gt = require(script.Parent.Parent.roblox_packages.gt)
local jabby_net = require(script.Parent.Parent.roblox_packages.jabby_net)

local NAMESPACE = "alicesaidhi/jabby-ecs-registry"

local NETWORK_LAYER = {

	obtain_world_capabilities = jabby_net.function_create(
		NAMESPACE, "obtain_world_capabilities",
		gt.none(),
		gt.table {
			entities_as_components = gt.bool(),
			has_relationships = gt.bool(),
			has_wildcard_relationships = gt.bool(),
			has_exclude = gt.bool(),
			exclude_only = gt.bool()
		}
	),

	check_result = jabby_net.function_create(
		NAMESPACE, "check_query",
		gt.string(),
		gt.array {
			why = gt.string(),
			span = (gt.vector() :: any) :: vector -- this isnt typed as a vector?
		}
	),

	query_world = jabby_net.function_create(
		NAMESPACE, "query_world",
		gt.string(),
		gt.union(
			{
				ok = gt.literal(true :: true),
				components = gt.array(gt.string()),
				can_be_inspected = gt.bool(),

				update_settings = gt.number(),
				update_query_data = gt.number(),
				update_value = gt.number(),
			},
			{
				ok = gt.literal(false :: false),
				issues = gt.array({
					why = gt.string(),
					span = (gt.vector() :: any) :: vector -- this isnt typed as a vector?
				})
			}
		)
	),

	update_query_data = jabby_net.socket_create(
		NAMESPACE, "update_query_data",
		gt.table {
			entities = gt.opt(gt.number()),
			time_taken = gt.opt(gt.number()),
			valid = gt.opt(gt.union(gt.literal(true :: true), gt.string())),
		}
	),

	update_settings = jabby_net.socket_create(
		NAMESPACE, "update_settings",
		gt.table {
			from = gt.number(),
			upto = gt.number(),
			live = gt.bool()
		}
	),

	update_value = jabby_net.socket_create(
		NAMESPACE, "update_value",
		gt.table {
			column = gt.number(),
			row = gt.number(),
			value = gt.string()
		}
	),

}

return NETWORK_LAYER