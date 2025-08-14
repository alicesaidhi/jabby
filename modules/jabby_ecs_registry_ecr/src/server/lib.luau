local RunService = game:GetService "RunService"

local ecr = require(script.Parent.Parent.Parent.roblox_packages.ecr)
local jabby_ecs_registry =
	require(script.Parent.Parent.Parent.roblox_packages.jabby_ecs_registry)
local jabby_query_parser =
	require(script.Parent.Parent.Parent.roblox_packages.jabby_query_parser)
local jabby_types =
	require(script.Parent.Parent.Parent.roblox_packages.jabby_types)
local jabby_util =
	require(script.Parent.Parent.Parent.roblox_packages.jabby_util)
local lua_object_notation =
	require(script.Parent.Parent.Parent.roblox_packages.lua_object_notation)
local lua_preview_notation =
	require(script.Parent.Parent.Parent.roblox_packages.lua_preview_notation)

local net = jabby_ecs_registry.net

type QueryData = {
	update_settings: typeof(net.update_settings:open_socket "server"),
	update_query_data: typeof(net.update_query_data:open_socket "server"),
	update_value: typeof(net.update_value:open_socket "server"),

	view: { unknown },
	include: { unknown },
	exclude: { unknown },

	values_a: { { string } },
	values_b: { { string } },

	from: number,
	upto: number,
	live_update: boolean,
}
type EntityInfo =
	{
		update_entity_components: typeof(net.update_entity_components:open_socket "server"),
		update_tracking_settings: typeof(net.update_tracking_settings:open_socket "server"),
		live_updates: boolean,
		entity: ecr.entity,

		components: { [unknown]: string },
	}

local function find_swap_pop<T>(list: { T }, value: T)
	local idx = table.find(list, value)
	if not idx then return end
	list[idx] = list[#list]
	list[#list] = nil
end

return function(applet: jabby_types.JabbyApplet<{
	world: ecr.Registry,
	components: { [string]: unknown },
}>)
	local id = applet.unique_id
	local query_world = net.query_world:connect(id)
	local get_capabilities = net.obtain_world_capabilities:connect(id)
	local check_valid = net.check_result:connect(id)
	local get_entity_info = net.get_entity_info:connect(id)
	local get_entity_component = net.get_entity_component:connect(id)
	local edit_entity = net.edit_entity:connect(id)

	local i = 0
	local active_queries: { QueryData } = {}

	local function is_component(value: string)
		return applet.configuration.components[value] ~= nil
	end

	local function is_component_id(entity: number) return true end

	local function get_component_name_from_id(id: number)
		return jabby_query_parser.into_string(
			{
				get_name = function()
					for name, component in applet.configuration.components do
						if component == id then return name end
					end
					return nil :: any
				end,
			} :: any,
			id
		)
	end

	local function get_component_from_name(name: string)
		return applet.configuration.components[name]
	end

	local function get_component_info(terms: { jabby_query_parser.Term })
		local components = {}
		local component_names = {}

		for idx, component in terms do
			if component.kind == "id" then
				assert(component.token, "no component text available")
				local text = component.token.text

				components[idx] = tonumber(text) :: unknown
				component_names[idx] = get_component_name_from_id(id)
			elseif component.kind == "named" then
				assert(component.token, "no component text available")
				local text = component.token.text

				components[idx] =
					applet.configuration.components[text] :: unknown
				component_names[idx] = text
			end
		end

		return components, component_names
	end

	local function get_all_components(entity: ecr.entity): { number }
		local owned = {}
		for name, component in applet.configuration.components do
			if applet.configuration.world:has(entity, component) then
				table.insert(owned, component)
			end
		end
		return owned
	end

	local function report_capabilities()
		for sender, resolve in get_capabilities:iter() do
			resolve {
				entities_as_components = false,
				has_relationships = false,
				has_wildcard_relationships = false,
				has_exclude = true,
				exclude_only = true,
			}
		end
	end

	local function check_if_valid()
		for sender, resolve, query_input in check_valid:iter() do
			local _, result = pcall(
				function()
					return jabby_query_parser.values(query_input, {
						is_component = is_component,
						is_id = is_component_id,
						features = {
							enable_excludes = true,
							enable_relationships = false,
							enable_wildcard = false,
							enable_only_excludes = true,
						},
					})
				end
			)

			resolve(result.issues)
		end
	end

	local function handle_world_query_request()
		for sender, resolve, query_input in query_world:iter() do
			local ok, result = pcall(
				function()
					return jabby_query_parser.values(query_input, {
						is_component = is_component,
						is_id = is_component_id,
						features = {
							enable_excludes = true,
							enable_relationships = false,
							enable_wildcard = false,
							enable_only_excludes = true,
						},
					})
				end
			)

			if not ok then
				resolve {
					ok = false :: false,
					issues = result.issues,
				}
			else
				assert(result.values)
				local view, view_names = get_component_info(result.values.view)
				local exclude = get_component_info(result.values.exclude)
				local include = get_component_info(result.values.include)

				local update_settings, update_settings_id =
					net.update_settings:open_socket(sender)
				local update_query_data, update_query_data_id =
					net.update_query_data:open_socket(sender)
				local update_value, update_value_id =
					net.update_value:open_socket(sender)

				local values_a = {}
				local values_b = {}

				for i = 1, #view + 1 do
					values_a[i] = {}
					values_b[i] = {}
				end

				local query_data: QueryData = {
					update_settings = update_settings,
					update_query_data = update_query_data,
					update_value = update_value,

					view = view,
					include = include,
					exclude = exclude,

					values_a = values_a,
					values_b = values_b,

					from = 1,
					upto = 20,
					live_update = true,
				}

				i += 1
				active_queries[i] = query_data

				resolve {
					ok = true :: true,
					update_settings = update_settings_id,
					update_query_data = update_query_data_id,
					update_value = update_value_id,

					components = view_names,
					can_be_inspected = false,
				}
			end
		end
	end

	local function handle_update_settings(query: QueryData)
		for packet in query.update_settings:receive() do
			query.upto = packet.upto
			query.from = packet.from
			query.live_update = packet.live

			for _, column in query.values_b do
				table.clear(column)
			end
		end
	end

	local function handle_update_value(query: QueryData)
		if query.update_value:status() == "waiting" then return end
		if query.update_query_data:status() == "waiting" then return end
		if not query.live_update then return end

		local components_to_query = query.include
		local idx, n = 0, 0

		for _, column in query.values_a do
			table.clear(column)
		end

		local start = os.clock()

		if #components_to_query == 0 then
			components_to_query = { ecr.entity }
		end

		for id in
			applet.configuration.world
				:view(unpack(components_to_query))
				:exclude(unpack(query.exclude))
				:iter()
		do
			n += 1

			if query.from > n then continue end
			if n >= query.upto then continue end
			idx += 1

			query.values_a[1][idx] = tostring(id)

			for column, component in query.view do
				local value = applet.configuration.world:try_get(id, component)
				local input = lua_preview_notation(value, 700)
				query.values_a[column + 1][idx] = input
			end
		end

		for column_idx, column in query.values_a do
			for row_idx, new_value in column do
				local old_value = query.values_b[column_idx][row_idx]
				if old_value == new_value then continue end
				query.update_value:send {
					column = column_idx,
					row = row_idx,
					value = new_value,
				}
			end
		end
		local finish = os.clock()

		query.values_b, query.values_a = query.values_a, query.values_b
		query.update_query_data:send {
			entities = n,
			time_taken = finish - start,
			valid = true,
		}
	end

	local function update_query_requests()
		for idx, query in active_queries do
			local is_closed = query.update_query_data:status() == "closed"
				or query.update_settings:status() == "closed"
				or query.update_value:status() == "closed"

			if is_closed then
				active_queries[idx] = nil
				query.update_settings:close()
				query.update_query_data:close()
				query.update_value:close()
			end

			if is_closed then continue end
			handle_update_settings(query)
			handle_update_value(query)
		end
	end

	local open: { EntityInfo } = {}

	local function get_new_update_entity(
		target: "server" | Player,
		id: unknown
	): EntityInfo?
		-- check if the entity can be converted into something usable
		if not tonumber(id) then return nil end

		local entity = tonumber(id)
		assert(entity)

		local update_entity_components =
			net.update_entity_components:open_socket(target)
		local update_tracking_settings =
			net.update_tracking_settings:open_socket(target)

		local entity_info: EntityInfo = {
			update_entity_components = update_entity_components,
			update_tracking_settings = update_tracking_settings,
			live_updates = true,
			entity = entity,

			components = {},
		}
		table.insert(open, entity_info)
		return entity_info
	end

	local function handle_entity_info(data: EntityInfo)
		local should_update = data.live_updates

		if data.update_entity_components:status() == "waiting" then return end
		if data.update_tracking_settings:status() == "waiting" then return end

		for packet in data.update_tracking_settings:receive() do
			data.live_updates = packet.live_updates
			if packet.refresh then should_update = true end
		end

		-- ecr
		if not should_update then return end
		for component in data.components do
			if not applet.configuration.world:has(data.entity, component) then
				local name = get_component_name_from_id(component)
				data.components[component] = nil
				data.update_entity_components:send {
					component = name,
					tag = false,
					value = nil,
				}
			end
		end

		for _, component in get_all_components(data.entity) do
			local value = applet.configuration.world:get(data.entity, component)
			local name = get_component_name_from_id(component)
			local previous_value = data.components[component]
			local new_value = lua_object_notation.output(value, true, true)
			local new_value_size = #new_value
			new_value = string.sub(new_value, 1, 160)

			if new_value_size > 160 then
				new_value ..= "..."
			end
			if new_value ~= previous_value then
				local tag = ecr.is_tag(component)
				data.components[component] = new_value
				data.update_entity_components:send {
					component = name,
					tag = tag,
					value = if tag then nil else new_value,
				}
			end
		end
	end

	local function process_all_entity_info()
		for i, data in open do
			if data.update_tracking_settings:status() == "closed" then
				-- this would cause a bug with the iterator but im lazy
				find_swap_pop(open, data)
				continue
			end

			handle_entity_info(data)
		end
	end

	local function handle_entity_info_requests()
		for sender, resolve, value in get_entity_info:iter() do
			local entity_info = get_new_update_entity(sender, value.entity)

			if entity_info then
				resolve {
					is_valid = true,
					allow_entity_editing = true,
					update_entity_components = entity_info.update_entity_components.socket_id,
					update_tracking_settings = entity_info.update_tracking_settings.socket_id,
				}
			else
				resolve { is_valid = false }
			end
		end
	end

	local function handle_get_component()
		for sender, resolve, value in get_entity_component:iter() do
			local id = value.entity
			local e = tonumber(id)

			if not e then
				resolve { exists = false, is_valid = false }
				continue
			end

			if not is_component(value.component) then
				resolve { exists = false, is_valid = false }
				continue
			end

			if not applet.configuration.world:contains(e) then
				resolve { exists = false, is_valid = false }
				continue
			end

			local component = get_component_from_name(value.component)
			if not applet.configuration.world:has(e, component) then
				resolve {
					exists = false :: false,
					is_valid = true,
					is_tag = ecr.is_tag(component),
					name = get_component_name_from_id(id),
				}
				continue
			end

			local component_value = applet.configuration.world:get(e, component)
			if ecr.is_tag(component) then
				resolve {
					exists = true :: true,
					component = nil,
					is_tag = true :: true,
					name = get_component_name_from_id(id),
				}
				continue
			else
				resolve {
					exists = true,
					component = lua_object_notation.output(
						component_value,
						true,
						false
					),
					is_tag = false,
					name = get_component_name_from_id(id),
				}
				continue
			end
		end
	end

	local function handle_edit_entity()
		for sender, resolve, value in edit_entity:iter() do
			local id = value.entity
			local e = tonumber(id)

			if not e then
				resolve { ok = false }
				continue
			end

			local is_ok = true
			for component, data in value.components do
				print(component, data)
				if not is_component(component) then
					is_ok = false
					continue
				end

				print "CONTINUE"

				if not applet.configuration.world:contains(e) then
					is_ok = false
					continue
				end

				local ctype = get_component_from_name(component)
				if data.tag then
					applet.configuration.world:set(e, ctype)
					continue
				elseif not data.tag and not data.value then
					applet.configuration.world:remove(e, ctype)
					continue
				end

				local old_value = applet.configuration.world:try_get(e, ctype)
				local ok, result = pcall(lua_object_notation.parse, data.value)

				if not ok then
					warn(result)
					is_ok = false
					continue
				end

				local new =
					lua_object_notation.compile(result, { old = old_value })

				if ecr.is_tag(ctype) then
					is_ok = false
					break
				else
					applet.configuration.world:set(e, ctype, new)
					continue
				end
			end

			resolve { ok = is_ok }
		end
	end

	local function system()
		report_capabilities()
		check_if_valid()
		handle_world_query_request()
		update_query_requests()

		handle_entity_info_requests()
		process_all_entity_info()
		handle_get_component()
		handle_edit_entity()
	end

	RunService.PostSimulation:Connect(system)
end
