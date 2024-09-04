local pebble = require(script.Parent.Parent.Parent.Parent.Parent.pebble)
local vide = require(script.Parent.Parent.Parent.Parent.Parent.vide)
local spawn_app = require(script.Parent.Parent.Parent.spawn_app)
local overview_scheduler = require(script.Parent.Parent.overview_scheduler)
local registry = require(script.Parent.Parent.registry)

local create = vide.create
local indexes = vide.indexes
local values = vide.values

type props = {

	servers: () -> {
		{
			host: "server" | Player,
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

		create "ScrollingFrame" {
			Size = UDim2.fromScale(1, 1),
			CanvasSize = UDim2.new(),

			AutomaticCanvasSize = Enum.AutomaticSize.Y,

			BackgroundTransparency = 1,

			ScrollBarThickness = 6,
			HorizontalScrollBarInset = Enum.ScrollBarInset.Always,

			pebble.padding {
				x = UDim.new(0, 1),
				right = UDim.new(0, 8)
			},

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
					automaticsize = Enum.AutomaticSize.Y,
	
					create "UIListLayout" {
						Padding = UDim.new(0, 8)
					},
	
					pebble.typography {
						text = `host: {value.host}\tvm id: {value.vm}`,
						wrapped = true
					},
	
					values(value.worlds, function(world)
						return pebble.button {
							size = UDim2.new(1, 0, 0, 30),
							text = `World: {world.name}`,

							activated = function()
								spawn_app.spawn_app(registry, {
									host = value.host,
									vm = value.vm,
									id = world.id
								})
							end
						}
					end) :: any,

					values(value.schedulers, function(scheduler)
						return pebble.button {
							size = UDim2.new(1, 0, 0, 30),
							text = `Scheduler: {scheduler.name}`,

							activated = function()
								spawn_app.spawn_app(overview_scheduler, {
									host = value.host,
									vm = value.vm,
									id = scheduler.id
								})
							end
						}
					end) :: any
	
				}
			end) :: any

		}

	}

end