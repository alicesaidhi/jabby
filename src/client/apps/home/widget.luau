local Players = game:GetService("Players")

local pebble = require(script.Parent.Parent.Parent.Parent.Parent.pebble)
local vide = require(script.Parent.Parent.Parent.Parent.Parent.vide)
local spawn_app = require(script.Parent.Parent.Parent.spawn_app)
local overview_scheduler = require(script.Parent.Parent.overview_scheduler)
local registry = require(script.Parent.Parent.registry)

local create = vide.create
local derive = vide.derive
local source = vide.source
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

	local selected = source(Players.LocalPlayer)

	local hosts = derive(function()
		local hosts = {}

		for _, server in props.servers() do
			local host = server.host
			hosts[host] = hosts[host] or {}
			table.insert(hosts[host], server)
		end

		hosts["all"] = props.servers()

		return hosts
	end)

	local options = derive(function()
		local options = {}
		options[Players.LocalPlayer] = "Client"
		options["all"] = "All"

		for host, servers in hosts() do
			options[host] = type(host) == "string" and host or `@{host.Name}`
		end	

		return options
	end)

	return pebble.widget {
		title = "Home",
		min_size = Vector2.new(230, 200),
		bind_to_close = props.destroy,
	
		pebble.container {

			create "UIListLayout" {
				Padding = UDim.new(0, 2),
				VerticalFlex = Enum.UIFlexAlignment.SpaceEvenly,
				HorizontalFlex = Enum.UIFlexAlignment.Fill
			},

			pebble.select {
				size = UDim2.new(1, 0, 0, 32),
	
				options = options :: any,
				selected = selected :: any,
				update_selected = selected
			},
	
			create "ScrollingFrame" {
				-- Size = UDim2.fromScale(1, 1),
				CanvasSize = UDim2.new(),
	
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
	
				BackgroundTransparency = 1,
	
				ScrollBarThickness = 6,
				HorizontalScrollBarInset = Enum.ScrollBarInset.Always,

				create "UIFlexItem" {
					FlexMode = Enum.UIFlexMode.Fill
				},
	
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
		
				values(function()
					return hosts()[selected()] or {}
				end, function(value, key)
					
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

	}

end