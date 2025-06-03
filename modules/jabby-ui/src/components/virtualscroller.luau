local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local component = require(script.Parent.Parent.util.component)
local container = require(script.Parent.container)
local scroll_container = require(script.Parent.scroll_container)

local effect = vide.effect
local source = vide.source
local changed = vide.changed
local values = vide.values
local batch = vide.batch
local untrack = vide.untrack
local read = vide.read

type Can<T> = T | () -> T
return component(function(p: {
	color: Can<Color3>?,
	transparency: Can<number>?,

    --- streams in items. when index is -1, should expect to be unused
	item: (index: () -> number) -> Instance,
	--- streams in separators. when index is -1, should expect to be unused
	separator: ((index: () -> number) -> Instance)?,

	item_size: Can<number>,
	separator_size: Can<number>?,

	max_items: (() -> number)?,
}, _)

    local items = source({} :: {vide.Source<number>})

	local absolute_size = source(Vector2.zero)
	local canvas_position = source(Vector2.zero)

	local item_size = p.item_size
	local separator_size = p.separator_size or 0

	local item = p.item
	local separator = p.separator

	local OVERFLOW = 4

	effect(function(previous_position: Vector2?)
		local absolute_size = absolute_size()
		local actual_canvas_position = canvas_position()
        local canvas_position = actual_canvas_position
        local canvas_velocity = actual_canvas_position - (previous_position or actual_canvas_position)
        local item_size = read(p.item_size)
        local separator_size = read(p.separator_size or 0)
        canvas_position = canvas_position + canvas_velocity

		local child_size = item_size + separator_size
		local total_required = math.ceil(absolute_size.Y / child_size) + OVERFLOW
		local sources = untrack(items)

		local min_index = math.floor(canvas_position.Y / child_size)
		local max_index = math.ceil((canvas_position.Y + absolute_size.Y) / child_size)

		local max_items = math.huge
		if p.max_items then
			max_items = p.max_items()
		end

		batch(function()
			untrack(function()
				-- mark any sources out of range as unused
				local unused = {}

				for i, s in sources do
					local index = s()

					if
						index >= math.max(min_index, 1)
						and index <= math.min(max_index, max_items)
					then continue end
					unused[i] = true
					s(-1)
				end

				-- add sources necessary
				if #sources < total_required then
					for i = #sources + 1, total_required do
						sources[i] = source(-1)
						unused[i] = true
					end
					items(sources)
				end

				-- update indexes of any sources that went unused
				local did_not_render = {}

				for i = math.max(min_index, 1), math.min(max_index, max_items) do
					did_not_render[i] = true
				end
				

				for _, s in sources do
					did_not_render[s()] = nil
				end

				for index in unused do
					local s = sources[index]
					local key = next(did_not_render)
					if not key then break end
					s(key)
					did_not_render[key] = nil
					unused[index] = nil
				end

				-- remove unnecessary sources
				if #sources > total_required then
					for i = #sources, 1, -1 do
						if unused[i] then
							table.remove(sources, i)
						end
						unused[i] = nil
						if #sources < total_required then break end
					end
					items(sources)
				end

			end)
		end)

        return actual_canvas_position
	end)

    return scroll_container {

		color = p.color,
		transparency = p.transparency,

        ch = function()
            local item_size = read(p.item_size)
            local separator_size = read(p.separator_size or 0)

            if p.max_items then
				return p.max_items() * (item_size + separator_size)
			else
				local absolute_size = absolute_size()
				local canvas_position = canvas_position()
				local child_size = item_size + separator_size
				local max_index = math.ceil((canvas_position.Y + absolute_size.Y) / child_size) + OVERFLOW
				return max_index * child_size
			end
        end,

        values(items, function(index: () -> number)
            return container {
                ws = 1, h = function()
                    return read(item_size) + read(separator_size or 0)
                end,

                y = function()
                    if index() == -1 then return -1000 end
                    
                    local item_size = read(p.item_size)
                    local separator_size = read(p.separator_size or 0)
                    return (item_size + separator_size) * (index() - 1)
                end,

                container {
                    name = "Item",
                    ws = 1, hs = 1,

                    item(index)
                },

                if separator then container {
                    name = "Separator",
                    ws = 1, hs = 1,

                    separator(index)
                } else nil
            }

        end),

		changed("AbsoluteSize", absolute_size),
		changed("CanvasPosition", canvas_position),

    }

end)