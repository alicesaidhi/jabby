local pebble = require(script.Parent.Parent.Parent.Parent.Parent.pebble)
local vide = require(script.Parent.Parent.Parent.Parent.Parent.vide)

local create = vide.create
local batch = vide.batch
local source = vide.source

type SystemId = number

type props = {
	host: Player | "server",
	vm: number,
	id: number,

	validate_query: (string) -> (),
	ok: () -> boolean,
	msg: () -> string,

	update_system_query: (query: string) -> (),
	current_query: () -> string,
	total_entities: () -> number,
	total_rows_per_page: () -> number,
	set_rows_per_page: (number) -> (),

	columns: () -> {{any}},

	destroy: () -> ()
}

return function(props: props)

	return pebble.widget {
		title = "Querying",
		subtitle = `host: {props.host} vm: {props.vm} id: {props.id}`,

		min_size = Vector2.new(200, 300),

		bind_to_close = props.destroy,

		create "Frame" {

			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,

			create "UIListLayout" {
				VerticalFlex = Enum.UIFlexAlignment.SpaceAround,
				Padding = UDim.new(0, 8)
			},

			pebble.textfield {
				size = UDim2.new(1, 0, 0, 30),
				placeholder = "Query",

				code = true,

				oninput = function(text)
					props.validate_query(text)
				end,

				enter = function(text)
					props.update_system_query(text)
				end
			},

			create "Frame" {
				Size = UDim2.new(1, 0, 0, 24),

				BackgroundTransparency = 1,

				Visible = function()
					return not props.ok() and #props.msg() > 0
				end,
				
				pebble.typography {
					text = props.msg
				},

			},

			-- create "Frame" {
				
			-- 	Size = UDim2.new(1, 0, 0, 38),

			-- 	BackgroundColor3 = pebble.theme.bg[2],
			-- 	AutomaticSize = Enum.AutomaticSize.Y,

			-- 	create "UICorner" {
			-- 		CornerRadius = UDim.new(0, 8)
			-- 	},

			-- 	create "UIListLayout" {
			-- 		FillDirection = Enum.FillDirection.Horizontal,
			-- 		Padding = UDim.new(0, 8),
			-- 		HorizontalFlex = Enum.UIFlexAlignment.SpaceEvenly,
			-- 		VerticalAlignment = Enum.VerticalAlignment.Center	
			-- 	},

			-- 	create "Frame" {
			-- 		AutomaticSize = Enum.AutomaticSize.XY,

			-- 		BackgroundTransparency = 1,

			-- 		create "UIListLayout" {
			-- 			FillDirection = Enum.FillDirection.Horizontal,
			-- 			Padding = UDim.new(0, 8),
			-- 			VerticalAlignment = Enum.VerticalAlignment.Center	
			-- 		},

			-- 		pebble.typography {
			-- 			text = "Rows per page:"
			-- 		},
	
			-- 		pebble.textfield {
			-- 			size = UDim2.fromOffset(50, 30),
			-- 			text = function()
			-- 				return tostring(rows_per_page_text())
			-- 			end,

			-- 			oninput = function(text)
			-- 				local old = rows_per_page_text()
			-- 				local n = tonumber(text)
			-- 				if n == nil then
			-- 					-- force set it without actually updating the value
			-- 					batch(function()
			-- 						rows_per_page_text(-1)
			-- 						rows_per_page_text(old)
			-- 					end)
			-- 				else
			-- 					rows_per_page_text(n)
			-- 				end
			-- 			end
			-- 		},

			-- 	},

			-- 	create "Frame" {
			-- 		AutomaticSize = Enum.AutomaticSize.XY,

			-- 		BackgroundTransparency = 1,

			-- 		create "UIListLayout" {
			-- 			FillDirection = Enum.FillDirection.Horizontal,
			-- 			Padding = UDim.new(0, 8),
			-- 			VerticalAlignment = Enum.VerticalAlignment.Center	
			-- 		},

			-- 		pebble.typography {
			-- 			text = "Page"
			-- 		},

			-- 		pebble.textfield {
			-- 			size = UDim2.fromOffset(50, 30),
			-- 			text = function()
			-- 				return tostring(page_text())
			-- 			end
			-- 		},

			-- 		pebble.typography {
			-- 			text = "/ 25"
			-- 		}

			-- 	}

			-- },

			pebble.background {
				size = UDim2.fromScale(1, 0),
				automaticsize = Enum.AutomaticSize.Y,

				create "UICorner" {
					CornerRadius = UDim.new(0, 8)
				},
				
				create "UIFlexItem" {
					FlexMode = Enum.UIFlexMode.Fill
				},

				pebble.shadow {},

				pebble.tablesheet {
					size = UDim2.fromScale(1, 1),

					column_sizes = function()
						local t = {}
						for i in props.columns() do
							t[i] = 100
						end
						t[1] = 50
						return t
					end,
					columns = props.columns,
	
					read_value = function(c, r)
						local column = props.columns()[c]
						if not column then return "" end
						return column[r] or ""
					end,
	
					on_click = function() end,
					on_click2 = function() end,
				}

			}

		}

	}

end