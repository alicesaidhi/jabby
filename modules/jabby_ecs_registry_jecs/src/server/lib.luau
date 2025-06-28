local RunService = game:GetService("RunService")

local jabby_ecs_registry = require(script.Parent.Parent.Parent.roblox_packages.jabby_ecs_registry)
local jabby_query_parser = require(script.Parent.Parent.Parent.roblox_packages.jabby_query_parser)
local jabby_types = require(script.Parent.Parent.Parent.roblox_packages.jabby_types)
local jecs = require(script.Parent.Parent.Parent.roblox_packages.jecs)
local lua_preview_notation = require(script.Parent.Parent.Parent.roblox_packages.lua_preview_notation)

local net = jabby_ecs_registry.net

type QueryData = {
	update_settings: typeof(net.update_settings:open_socket("server")),
	update_query_data: typeof(net.update_query_data:open_socket("server")),
	update_value: typeof(net.update_value:open_socket("server")),
	
	view: { unknown },
	include: { unknown },
	exclude: { unknown },

	values_a: { { string } },
	values_b: { { string } },

	from: number,
	upto: number,
	live_update: boolean
}

return function(applet: jabby_types.JabbyApplet<{
	world: jecs.World
}>)
	local id = applet.unique_id
	local query_world = net.query_world:connect(id)
	local get_capabilities = net.obtain_world_capabilities:connect(id)
	local check_valid = net.check_result:connect(id)
	local world = applet.configuration.world

	local i = 0
	local active_queries: { QueryData } = {}
	local name_query = world:query(jecs.Name):cached()

	local function get_component(value: string): jecs.Entity?
		for id, name in name_query:iter() do
			if name == value then return id end
		end

		if value == "*" then return jecs.Wildcard end
		return nil
	end
	
	local function is_component(value: string)
		for id, name in name_query:iter() do
			if name == value then return true end
		end
		return false
	end

	local function is_component_id(entity: jecs.Entity)
		return world:contains(entity)
	end

	local function get_component_name_from_id(id: jecs.Entity)
		if jecs.IS_PAIR(id) then
			local left = get_component_name_from_id(jecs.ECS_PAIR_FIRST(id))
			local right = get_component_name_from_id(jecs.ECS_PAIR_SECOND(id))
			return `({left}, {right})`
		elseif id == jecs.Wildcard then
			return "*"
		else
			return world:get(id, jecs.Name) or `${id}`
		end
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

				components[idx] = get_component(text)
				component_names[idx] = text
			elseif component.kind == "relationship" then
				assert(component.tokens.value)
				assert(component.tokens.value.left)
				assert(component.tokens.value.right)
				assert(component.tokens.value.left.token)
				assert(component.tokens.value.right.token)

				local left = get_component(component.tokens.value.left.token.text)
				local right = get_component(component.tokens.value.right.token.text)

				assert(left, `no component named {component.tokens.value.left.token.text}`)
				assert(right, `no component named {component.tokens.value.right.token.text}`)

				components[idx] = jecs.pair(left, right)
				component_names[idx] = get_component_name_from_id(jecs.pair(left, right))
			end
		end

		return components, component_names
	end

	local function report_capabilities()
		for sender, resolve in get_capabilities:iter() do
			resolve({
				entities_as_components = true,
				has_relationships = true,
				has_wildcard_relationships = true,
				has_exclude = true,
				exclude_only = false
			})
		end
	end

	local function check_if_valid()
		for sender, resolve, query_input in check_valid:iter() do
			local _, result = pcall(function()
				return jabby_query_parser.values(query_input, {
					is_component = is_component,
					is_id = is_component_id,
					features = {
						enable_excludes = true,
						enable_relationships = true,
						enable_wildcard = true,
						enable_only_excludes = false,
					},
				})
			end)
			
			resolve(result.issues)
		end
	end

	local function handle_world_query_request()
		for sender, resolve, query_input in query_world:iter() do
			local ok, result = pcall(function()
				return jabby_query_parser.values(query_input, {
					is_component = is_component,
					is_id = is_component_id,
					features = {
						enable_excludes = true,
						enable_relationships = true,
						enable_wildcard = true,
						enable_only_excludes = false,
					},
				})
			end)

			if not ok then
				resolve({
					ok = false :: false,
					issues = result.issues
				})
			else
				assert(result.values)
				local view, view_names = get_component_info(result.values.view)
				local exclude = get_component_info(result.values.exclude)
				local include = get_component_info(result.values.include)

				local update_settings, update_settings_id = net.update_settings:open_socket(sender)
				local update_query_data, update_query_data_id = net.update_query_data:open_socket(sender)
				local update_value, update_value_id = net.update_value:open_socket(sender)

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
					live_update = true
				}

				i += 1
				active_queries[i] = query_data

				resolve({
					ok = true :: true,
					update_settings = update_settings_id,
					update_query_data = update_query_data_id,
					update_value = update_value_id,

					components = view_names,
					can_be_inspected = false
				})
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

		for id in world:query(unpack(components_to_query)):without(unpack(query.exclude)):iter() do
			n += 1

			if query.from > n then continue end
			if n >= query.upto then continue end
			idx += 1

			query.values_a[1][idx] = tostring(id)
			
			for column, component in query.view do
				local value = world:get(id, component)
				local input = lua_preview_notation(value, 700)
				query.values_a[column + 1][idx] = input
			end
		end
		
		for column_idx, column in query.values_a do
			for row_idx, new_value in column do
				local old_value = query.values_b[column_idx][row_idx]
				if old_value == new_value then continue end
				query.update_value:send({
					column = column_idx,
					row = row_idx,
					value = new_value
				})
			end
		end
		local finish = os.clock()

		query.values_b, query.values_a = query.values_a, query.values_b
		query.update_query_data:send({
			entities = n,
			time_taken = finish - start,
			valid = true
		})
	end

	local function update_query_requests()
		for idx, query in active_queries do
			local is_closed =
				query.update_query_data:status() == "closed" 
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

	local function system()
		report_capabilities()
		check_if_valid()
		handle_world_query_request()
		update_query_requests()
	end

	RunService.Heartbeat:Connect(system)
end