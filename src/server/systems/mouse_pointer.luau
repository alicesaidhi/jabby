local queue = require(script.Parent.Parent.Parent.modules.queue)
local remotes = require(script.Parent.Parent.Parent.modules.remotes)
local reverse_connector = require(script.Parent.Parent.Parent.modules.reverse_connector)
local types = require(script.Parent.Parent.Parent.modules.types)
local public = require(script.Parent.Parent.public)


return function()

	local send_mouse_pointer = queue(remotes.send_mouse_pointer)

	return function()

		for incoming, world_id, pos, dir in send_mouse_pointer:iter() do
			local world_data: types.World = public[world_id]
			local world = world_data.world
			local outgoing = reverse_connector(incoming)

			if world_data.entities == nil then continue end
			if not world_data or world_data.class_name ~= "World" then continue end

			local result = workspace:Raycast(pos, dir * 1000)
			
			if not result then
				remotes.send_mouse_entity:fire(
					outgoing,
					world_id
				)
				continue
			end

			local part = result.Instance
			local entity = world_data.entities[part]

			while entity == nil and part.Parent ~= game do
				part, entity = part.Parent, world_data.entities[part]
			end

			if not entity then 
				remotes.send_mouse_entity:fire(
					outgoing,
					world_id
				)
				continue
			end

			local MAX_SIZE = 750
			local has_more = false
			local n = #`id: {entity}`
			local strings = {`id: {entity}`}

			for id, name in world:query(world_data.debug).iter() do
				if world:has(entity, id) then
					local v = world:get(entity, id)
					local str

					if typeof(v) == "string" then
						str = `"{v}"`
					elseif typeof(v) == "table" then
						local temp_n = 0
						local temp_b = {}

						for key, value in v do
							if #temp_b > 0 then
								table.insert(temp_b, "; ")
							end
							 
							local str_of_v = if type(value) == "string" then `"{value}"` else tostring(value)
							local str = `{key}: {str_of_v}`

							if temp_n + #str + 2 > 100 then
								table.insert(temp_b, "...")
								break
							else
								table.insert(temp_b, str)
							end
						end

						str = `\{{table.concat(temp_b)}\}`
					else
						str = tostring(v)
					end

					local to_append = `\n{name}: {str}`
					if MAX_SIZE > n + #to_append then
						n += #to_append
						table.insert(strings, to_append)
					else
						has_more = true
					end
				end
			end

			local str = table.concat(strings)
			if has_more then str = str .. "\n..." end

			remotes.send_mouse_entity:fire(
				outgoing,
				world_id,
				part,
				str --todo: get all components for entity
			)

		end

	end
end