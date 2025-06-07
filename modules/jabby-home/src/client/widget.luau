local Players = game:GetService("Players")

local jabby_types = require(script.Parent.Parent.Parent.roblox_packages.jabby_types)
local jabby_ui = require(script.Parent.Parent.Parent.roblox_packages.jabby_ui)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local net = require(script.Parent.Parent.net)
local applets = require(script.Parent.applets)
local performance = require(script.Parent.performance)

local cleanup = vide.cleanup

return function()

	local store = vide.source({} :: { [jabby_types.Host]: {
		memory: vide.Source<number>,
		heartbeat_time: vide.Source<number>,
		render_gpu_time: vide.Source<number>,
		render_cpu_time: vide.Source<number>,
		
		applets: {{ name: string, description: string, id: number, client: ModuleScript }} } }
	)
	local open_connections = {}

	local function obtain_store_data(host: jabby_types.Host)
		local data = net.get_registered_applets:invoke({ to = host, id = 0 }, nil)
		data:after(function(result)
			if not result.ok then return end
			
			local memory = vide.source(0)
			local heartbeat_time = vide.source(0)
			local render_gpu_time = vide.source(0)
			local render_cpu_time = vide.source(0)

			store()[host] = {
				memory = memory,
				heartbeat_time = heartbeat_time,
				render_gpu_time = render_gpu_time,
				render_cpu_time = render_cpu_time,
				applets = result.value.applets
			}
			store(store())

			local socket = net.communicate_frame_time:accept_socket(host, result.value.socket)
			print(socket:status())
			task.delay(1, function()
				print(socket:status(), host)
			end)
			socket:on_event(function(packet)
				memory(packet.memory)
				heartbeat_time(packet.heartbeattime)
				render_gpu_time(packet.rendergputime)
				render_cpu_time(packet.rendercputime)
			end)

			open_connections[host] = socket
		end)
	end

	for _, player in Players:GetPlayers() do
		obtain_store_data(player)
	end
	obtain_store_data("server")
	Players.PlayerAdded:Connect(obtain_store_data)

	return jabby_ui.widget.root {
		jabby_ui.widget.horizontal {

			jabby_ui.widget.tabs {
				applets(store)
			},

			jabby_ui.widget.tabs {
				performance(store)
			},

		}
	}

end