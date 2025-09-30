local assets = require(script.Parent.Parent.util.assets)
local component = require(script.Parent.Parent.util.component)
local conditional = require(script.Parent.Parent.util.conditional)
local container = require(script.Parent.container)
local context_menu = require(script.Parent.context_menu)
local cornered = require(script.Parent.cornered)
local ignore = require(script.Parent.ignore)
local resizable_bar = require(script.Parent.resizable_bar)
local text = require(script.Parent.text)
local theme = require(script.Parent.Parent.util.theme)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local virtualscroller = require(script.Parent.virtualscroller)

local source = vide.source
local derive = vide.derive
local indexes = vide.indexes
local changed = vide.changed
local show = vide.show
local untrack = vide.untrack
local effect = vide.effect

type Can<T> = T | () -> T
return component(function<T>(
	p: {
		min_sizes: (() -> { number })?,
		use_offset: (() -> { number })?,
		suggested_sizes: { number }?,
		disable_top_corners: boolean,

		columns: () -> { () -> { T } },

		enable_sort_key: boolean?,
		auto_sort: boolean?,
		sort_column: (() -> number)?,
		set_sort_column: ((number) -> ())?,
		sort_direction: (() -> "ascending" | "descending")?,
		set_sort_direction: (("ascending" | "descending") -> ())?,
		get_value: (() -> unknown)?,

		shown: (() -> { number })?,
		set_shown: (({ number }) -> ())?,

		grouped_by: () -> number?,
		set_grouped_by: (number?) -> (),

		header: (value: () -> T, column: number, row: number) -> Instance,
		field: (
			value: () -> T,
			column: () -> number,
			row: () -> number
		) -> Instance,
		element_size: Can<number>?,
	},
	children
)
	local sort_column = p.sort_column :: never or source(0)
	local set_sort_column = p.set_sort_column :: never or sort_column
	local sort_direction = p.sort_direction :: never
		or source("ascending" :: "ascending" | "descending")
	local set_sort_direction = p.set_sort_direction or sort_direction

	local shown: () -> { number } = p.shown or source({} :: { number })
	local set_shown: ({ number }) -> () = p.set_shown or shown
	local column_count = derive(function() return #p.columns() end)

	local grouped_by: () -> number? = p.grouped_by or source(nil)
	local set_grouped_by: (number?) -> () = p.set_grouped_by or grouped_by

	local categories = derive(function(): { [T]: { number } }
		local column_idx = grouped_by()
		if column_idx == nil then
			local entries = {}

			local column = p.columns()[1]()

			for i = 2, #column do
				table.insert(entries, i)
			end

			return { entries }
		end

		local key_column = p.columns()[column_idx]()
		local categories: { [T]: { number } } = {}

		for idx, value in key_column do
			if idx == 1 then continue end
			if typeof(value) == "function" then value = value() end

			if categories[value] == nil then categories[value] = {} end

			table.insert(categories[value], idx)
		end

		return categories
	end)
	local total_categories = derive(function()
		local n = 0

		for _ in categories() do
			n += 1
		end

		return n
	end)

	local displayed = derive(function()
		local columns = p.columns()
		local t = {}

		for i, idx in shown() do
			t[i] = columns[idx]
		end

		return t
	end)
	local display_count = derive(function() return #displayed() end)

	effect(function()
		local t = untrack(shown)
		for idx = 1, column_count() do
			t[idx] = idx
		end
		set_shown(t)
	end)

	local sizes = source({} :: { number })
	local splits = source({} :: { number })

	local columns = derive(function()
		if
			p.auto_sort ~= true
			or p.enable_sort_key ~= true
			or sort_column() == 0
		then
			local categories = categories()
			local entries = table.create(#categories)

			for i, category in categories do
				for _, idx in category do
					table.insert(entries, idx)
				end
			end

			return entries
		else
			local columns = p.columns()
			local sort_by_column = columns[sort_column()]()
			local categories = categories()
			local entries = {}

			for _, category in categories do
				-- we should be ok on sorting category, because the order it appears in does not really matter.
				if p.get_value then
					local get = p.get_value
					if sort_direction() == "ascending" then
						table.sort(
							category,
							function(a, b): boolean
								return get(sort_by_column[a])
									> get(sort_by_column[b])
							end
						)
					else
						table.sort(
							category,
							function(a, b): boolean
								return get(sort_by_column[a])
									< get(sort_by_column[b])
							end
						)
					end
				elseif sort_direction() == "ascending" then
					table.sort(
						category,
						function(a, b): boolean
							return sort_by_column[a] > sort_by_column[b]
						end
					)
				else
					table.sort(
						category,
						function(a, b): boolean
							return sort_by_column[a] < sort_by_column[b]
						end
					)
				end
			end

			for _, category in categories do
				for _, idx in category do
					table.insert(entries, idx)
				end
			end

			return entries
		end
	end)

	local function field(idx: number)
		local column_idx = function() return shown()[idx] end

		local is_first = function()
			return idx == 1 and p.disable_top_corners ~= true
		end

		local is_last = function()
			return idx == display_count() and p.disable_top_corners ~= true
		end

		local hover = source(false)
		local hold = source(false)
		local enabled = p.enable_sort_key

		local function depth_bg()
			return if not enabled
				then 1
				elseif hold() then 1
				elseif hover() then 4
				else 2
		end

		local show_context = source(false)

		return cornered {
			ws = 1,
			hs = 1,

			color = theme.bg(depth_bg),

			topleft = function()
				return if is_first() then theme.base_table_corner() else 0
			end,
			topright = function()
				return if is_last() then theme.base_table_corner() else 0
			end,

			pad = { x = conditional(theme.compact, 6, 8) },
			flex = {
				direction = "row",
				justify = "left",
				align = "center",
				pad = 4,
			},

			hold = hold :: (boolean) -> (),
			hover = hover :: (boolean) -> (),

			enabled = source(p.enable_sort_key or false),
			clicked = function()
				if sort_column() == column_idx() then
					if sort_direction() == "descending" then
						set_sort_direction "ascending"
					elseif sort_direction() == "ascending" then
						set_sort_column(0)
						set_sort_direction "descending"
					end
				else
					set_sort_column(column_idx())
					set_sort_direction "descending"
				end
			end,
			rightclick = function() show_context(true) end,

			show(show_context, function()
				local view = { kind = "group" }
				local group_by = { kind = "group" }

				for idx, column in p.columns() do
					table.insert(view, {
						kind = "action",
						text = column()[1],
						image = if table.find(shown(), idx)
							then assets.checked
							else nil,
						clicked = function()
							local is_in = table.find(shown(), idx)
							if is_in then
								table.remove(shown(), is_in)
								set_shown(shown())
							else
								local at = 1
								for i, value in shown() do
									if value > idx then break end
									at += 1
								end

								table.insert(shown(), at, idx)
								set_shown(shown())
							end
						end,
					})
				end

				for idx, column in p.columns() do
					table.insert(group_by, {
						kind = "action",
						text = `Group By {column()[1]}`,
						image = if grouped_by() == idx
							then assets.checked
							else nil,
						clicked = function()
							if grouped_by() == idx then
								set_grouped_by(nil)
							else
								set_grouped_by(idx)
							end
						end,
					})
				end

				return context_menu {
					show_default = true,
					shown = show_context,

					view,
					group_by,
				}
			end),

			show(
				function() return sort_column() == column_idx() end,
				function()
					return container {
						w = 16,
						h = 16,
						ys = 0.5,
						x = 8,
						z = 100,
						order = -1,

						color = theme.bg_fg_high(depth_bg),

						image = assets.arrows,
						rect_size = Vector2.new(64, 64),
						rect_offset = function()
							return if sort_direction() == "ascending"
								then Vector2.zero
								else Vector2.new(64, 0)
						end,
					}
				end
			),

			if p.header
				then function()
					column_idx()
					return untrack(function(): Instance?
						if column_idx() == nil then return nil end

						return p.header(function()
							local c = p.columns()[column_idx()]
							if not c then return "" end
							return c()[1]
						end, column_idx(), 1)
					end)
				end
				else text {
					xalign = "left",
					text = function()
						local column = p.columns()[column_idx()]
						return tostring(column and column()[1])
					end,

					weight = 700,
				},
		}
	end

	local ysize = source(0)

	return container {
		name = "Table",
		flex = { justify = "fill" },

		stroke = theme.bg(-4),
		thickness = 1,
		corner = if p.disable_top_corners then 0 else theme.base_table_corner,

		ignore {
			indexes(
				splits,
				function(split: () -> number, idx)
					return container {
						xs = split,
						w = 1,
						hr = ysize,
						z = 100,

						color = theme.bg(-4),
					}
				end
			),
		},

		container {
			name = "Resizable",

			ws = 1,
			h = conditional(theme.compact, 24, 32),
			flex = {},

			resizable_bar {
				ws = 1,
				hs = 1,

				min_sizes = p.min_sizes,
				use_offset = p.use_offset,

				sizes = sizes,
				fields = function() return table.create(display_count(), field) end,
				splits = splits,
			},
		},

		virtualscroller {
			name = "Contents",

			ws = 1,
			grow = 1,
			shrink = 1,
			color = theme.bg(-3),

			min_items = 1,
			max_items = function() return #p.columns()[1]() - 1 end,

			item_size = p.element_size or theme.table_element_size,

			item = function(row: () -> number)
				local function is_even() return row() % 2 == 1 end

				local function actual_row()
					local row = columns()[row()]
					return row or 1
				end

				return container {
					{ Name = actual_row },

					ws = 1,
					hs = 1,
					color = conditional(is_even, theme.bg(0), theme.bg(-1)),
					flex = { direction = "row", justify = "left" },

					indexes(sizes, function(size: () -> number, column: number)
						local old

						local function value()
							if displayed()[column] == nil then return old end
							local value =
								displayed()[column]()[math.max(2, actual_row())]
							old = value
							return old
						end

						return container {
							name = `{column}`,
							ws = size,
							hs = 1,

							p.field(
								value,
								function() return shown()[column] end,
								actual_row
							),
						}
					end),
				}
			end,
		},

		cornered {
			name = "",
			ws = 1,
			h = theme.base_table_corner,
			auto = "y",

			bottomleft = theme.base_table_corner,
			bottomright = theme.base_table_corner,

			color = theme.bg(1),

			changed("AbsoluteSize", function(size: Vector2) ysize(-size.Y) end),

			children,
		},
	}
end)
