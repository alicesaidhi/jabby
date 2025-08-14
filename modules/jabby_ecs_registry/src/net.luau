local gt = require(script.Parent.Parent.roblox_packages.gt)
local jabby_net = require(script.Parent.Parent.roblox_packages.jabby_net)

local NAMESPACE = "alicesaidhi/jabby-ecs-registry"

local NETWORK_LAYER = {

	obtain_world_capabilities = jabby_net.function_create(
		NAMESPACE,
		"obtain_world_capabilities",
		gt.none(),
		gt.table {
			entities_as_components = gt.bool(),
			has_relationships = gt.bool(),
			has_wildcard_relationships = gt.bool(),
			has_exclude = gt.bool(),
			exclude_only = gt.bool(),
		}
	),

	check_result = jabby_net.function_create(
		NAMESPACE,
		"check_query",
		gt.string(),
		gt.array {
			why = gt.string(),
			span = (gt.vector() :: any) :: vector, -- this isnt typed as a vector?
		}
	),

	query_world = jabby_net.function_create(
		NAMESPACE,
		"query_world",
		gt.string(),
		gt.union({
			ok = gt.literal(true :: true),
			components = gt.array(gt.string()),
			can_be_inspected = gt.bool(),

			update_settings = gt.number(),
			update_query_data = gt.number(),
			update_value = gt.number(),
		}, {
			ok = gt.literal(false :: false),
			issues = gt.array {
				why = gt.string(),
				span = (gt.vector() :: any) :: vector, -- this isnt typed as a vector?
			},
		})
	),

	update_query_data = jabby_net.socket_create(
		NAMESPACE,
		"update_query_data",
		gt.table {
			entities = gt.opt(gt.number()),
			time_taken = gt.opt(gt.number()),
			valid = gt.opt(gt.union(gt.literal(true :: true), gt.string())),
		}
	),

	update_settings = jabby_net.socket_create(
		NAMESPACE,
		"update_settings",
		gt.table {
			from = gt.number(),
			upto = gt.number(),
			live = gt.bool(),
		}
	),

	update_value = jabby_net.socket_create(
		NAMESPACE,
		"update_value",
		gt.table {
			column = gt.number(),
			row = gt.number(),
			value = gt.string(),
		}
	),

	-- entity editing

	get_entity_info = jabby_net.function_create(
		NAMESPACE,
		"get_entity_info",
		gt.table {
			entity = gt.any(),
		},
		gt.union({
			is_valid = gt.literal(true :: true),
			allow_entity_editing = gt.bool(),
			update_entity_components = gt.number(),
			update_tracking_settings = gt.number(),
		}, {
			is_valid = gt.literal(false :: false),
		})
	),

	get_entity_component = jabby_net.function_create(
		NAMESPACE,
		"get_entity_component",
		gt.table {
			entity = gt.any(),
			component = gt.string(),
		},
		gt.union({
			exists = gt.literal(false :: false),
			is_valid = gt.literal(false :: false), -- implies that the entity and component is valid
		}, {
			exists = gt.literal(false :: false),
			is_valid = gt.literal(true :: true), -- implies that the entity and component is valid
			is_tag = gt.bool(),
			name = gt.string(),
		}, {
			exists = gt.literal(true :: true),
			component = gt.string(),
			is_tag = gt.literal(false :: false),
			name = gt.string(),
		}, {
			exists = gt.literal(true :: true),
			is_tag = gt.literal(true :: true),
			name = gt.string(),
		})
	),

	edit_entity = jabby_net.function_create(
		NAMESPACE,
		"edit_entity",
		gt.table {
			entity = gt.any(),
			components = gt.dictionary(
				gt.string(),
				gt.union({
					value = gt.literal(nil),
					tag = gt.literal(nil),
				}, {
					value = gt.string(),
					tag = gt.literal(nil),
				}, {
					value = gt.literal(nil),
					tag = gt.bool(),
				})
			),
		},
		gt.table {
			ok = gt.bool(),
		}
	),

	update_tracking_settings = jabby_net.socket_create(
		NAMESPACE,
		"update_tracking_settings",
		gt.table {
			live_updates = gt.bool(),
			refresh = gt.bool(),
		}
	),

	update_entity_components = jabby_net.socket_create(
		NAMESPACE,
		"update_entity_component",
		gt.table {
			component = gt.string(),
			value = gt.opt(gt.string()),
			tag = gt.bool(),
		}
	),
}

return NETWORK_LAYER
