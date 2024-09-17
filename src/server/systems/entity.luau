local jecs = require(script.Parent.Parent.Parent.Parent.jecs)
local lon = require(script.Parent.Parent.Parent.modules.lon)
local queue = require(script.Parent.Parent.Parent.modules.queue)
local remotes = require(script.Parent.Parent.Parent.modules.remotes)
local reverse_connector = require(script.Parent.Parent.Parent.modules.reverse_connector)
local traffic_check = require(script.Parent.Parent.Parent.modules.traffic_check)
local types = require(script.Parent.Parent.Parent.modules.types)
local public = require(script.Parent.Parent.public)
local query_parser = require(script.Parent.Parent.query_parser)

local function get_all_components(world, entity): {}
	local record = world.entityIndex.sparse[entity]
	if not record then return {} end
	local archetype = record.archetype
	if not archetype then return {} end

	local components = {}
	for _, ty in archetype.types do 
		table.insert(components, ty)
	end
	return components
end

local function convert_component(world, debug, entity): string
 	if jecs.IS_PAIR(entity) then
		local left = convert_component(world, debug, jecs.pair_first(world, entity))
		local right = convert_component(world, debug, jecs.pair_second(world, entity))
		return `({left}, {right})`
	else
		return world:get(entity, debug) or `${tostring(entity)}`
	end
end

local TAG = newproxy()

local function get_component(ctype_name: string, map_components: {[string]: string})

	local function get_entity(ctype)
		local value = ctype.value

		if value.type == "Entity" then
			return value.entity
		elseif value.type == "Name" then
			return map_components[value.name]
		end
		error("bad")
	end

	local entity_to_set
	local parse = query_parser(ctype_name)[1]
	if parse.type == "Component" then
		entity_to_set = get_entity(parse)
	elseif parse.type == "Relationship" then
		local left, right = jecs.Wildcard, jecs.Wildcard

		if parse.left.type == "Component" then
			left = get_entity(parse.left)
		end

		if parse.right.type == "Component" then
			right = get_entity(parse.right)
		end

		entity_to_set = jecs.pair(left, right)
	end

	return entity_to_set

end

return function()

	local inspect_entity = queue(remotes.inspect_entity)
	local update_inspect_settings = queue(remotes.update_inspect_settings)
	local stop_inspect_entity = queue(remotes.stop_inspect_entity)
	local update_entity = queue(remotes.update_entity)
	local delete_entity = queue(remotes.delete_entity)

	local validate_entity = queue(remotes.validate_entity_component)

	local inspectors = {}
	
	return function()

		for incoming, world_id, ctype_name in validate_entity:iter() do
			local world: types.World = public[world_id]
			local outgoing = reverse_connector(incoming)

			if not traffic_check.check_no_wl(incoming.host) then continue end
			if not world or world.class_name ~= "World" then continue end

			local map_components = {}
			for id, name in world.world:query(world.debug):iter() do
				map_components[name] = id
			end

			local ok, reason = pcall(get_component, ctype_name, map_components)

			remotes.validate_entity_component_result:fire(
				outgoing, world_id, ctype_name, ok, not ok and reason or nil
			)
		end

		for incoming, world_id, entity, inspect_id in inspect_entity:iter() do
			local world: types.World = public[world_id]
			local outgoing = reverse_connector(incoming)

			if not traffic_check.check_no_wl(incoming.host) then continue end
			if not world or world.class_name ~= "World" then continue end

			inspectors[inspect_id] = {
				outgoing = outgoing,
				world = world,
				entity = entity,
				paused = false,

				new_values = {},
				old_values = {}
			}
		end

		for incoming, inspect_id in stop_inspect_entity:iter() do
			if not traffic_check.check_no_wl(incoming.host) then continue end
			inspectors[inspect_id] = nil
		end

		for incoming, inspect_id in delete_entity:iter() do
			if not traffic_check.check_no_wl(incoming.host) then continue end
			local inspect_data = inspectors[inspect_id]
			local world_data = inspect_data.world
			local world = world_data.world
			local entity = inspect_data.entity

			world:delete(entity)
		end

		for incoming, inspect_id, settings in update_inspect_settings:iter() do
			if not traffic_check.check_no_wl(incoming.host) then continue end
			local inspect_data = inspectors[inspect_id]
			if not inspect_data then continue end
			inspect_data.paused = settings.paused
		end

		for incoming, inspect_id, changes in update_entity:iter() do
			if not traffic_check.check_no_wl(incoming.host) then continue end
			local inspect_data = inspectors[inspect_id]
			local world_data = inspect_data.world
			local world = world_data.world
			local entity = inspect_data.entity

			local map_components = {}
			for id, name in world:query(world_data.debug):iter() do
				map_components[name] = id
			end

			for ctype_name, value in changes do

				-- get the component we need to set
				local ok, entity_to_set = pcall(get_component, ctype_name, map_components)

				if not ok then
					warn("attempted to set", ctype_name, "to", value)
					warn(entity_to_set)
					continue
				end

				local ok, result = pcall(lon.parse, value)

				if not ok then
					warn("attempted to set", ctype_name, "to", value)
					warn(result)
					continue
				end

				local ok, data = pcall(
					lon.compile,
					result,
					lon_vars
				)

				if not ok then
					warn("attempted to set", ctype_name, "to", value)
					warn(data)
					continue
				end

				if data == nil then
					world:remove(entity, entity_to_set)
				elseif data == TAG then
					world:set(entity, entity_to_set)
				else
					world:set(entity, entity_to_set, data)
				end
			end
		end

		for inspect_id, inspector_data in inspectors do
			local world = inspector_data.world.world
			local entity = inspector_data.entity

			if inspector_data.paused then continue end
			if world:contains(entity) == false then continue end

			local new_values = inspector_data.new_values
			local old_values = inspector_data.old_values

			local components = get_all_components(world, entity)

			for _, component in components do
				local name = convert_component(world, inspector_data.world.debug, component)
				local value = world:get(entity, component)
				new_values[name] = if value ~= nil then value else TAG
			end

			for name, new_value in new_values do
				local old_value = old_values[name]

				if old_value ~= new_value then
					remotes.inspect_entity_update:fire(
						inspector_data.outgoing,
						inspect_id,
						name,
						if new_value == TAG then "" else lon.output(new_value, false)
					)
				end
			end

			for name, value in old_values do
				local new_value = new_values[name]

				if new_value == nil then
					remotes.inspect_entity_update:fire(
						inspector_data.outgoing,
						inspect_id,
						name,
						nil
					)
				end
			end
			
			table.clear(old_values)

			inspector_data.new_values = old_values
			inspector_data.old_values = new_values

		end

	end
end