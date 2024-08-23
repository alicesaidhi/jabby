local pebble = require(script.Parent.Parent.Parent.Parent.Parent.pebble)
local vide = require(script.Parent.Parent.Parent.Parent.Parent.vide)

local create = vide.create
local indexes = vide.indexes
local values = vide.values

type props = {

	servers: () -> {
		{
			namespace: "server" | "client",
			vm: number,

			schedulers: () -> {
				{id: number, name: string}
			},
			worlds: () -> {
				{id: number, name: string}
			}
		}
	},

	destroy: () -> ()

}

return function(props: props)

	return pebble.widget {
		title = "Home",
		min_size = Vector2.new(230, 200),
		bind_to_close = props.destroy,

		create "Frame" {
			Size = UDim2.fromScale(1, 1),

			BackgroundTransparency = 1,

			create "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				Padding = UDim.new(0, 8),
				Wraps = true
			},
	
			values(props.servers, function(value, key)
				
				return pebble.pane{
					name = "",
					size = UDim2.fromOffset(200, 0),
					automaticsize = Enum.AutomaticSize.XY,
	
					create "UIListLayout" {
						Padding = UDim.new(0, 8)
					},
	
					pebble.typography {
						text = `namespace: {value.namespace}\nvm id: {value.vm}`
					},
	
					values(value.worlds, function(world)
						return pebble.button {
							text = `World {world.name}`
						}
					end) :: any,

					values(value.schedulers, function(scheduler)
						return pebble.button {
							size = UDim2.new(1, 0, 0, 30),
							text = `Scheduler {scheduler.name}`
						}
					end) :: any
	
				}
			end) :: any

		}

	}

end