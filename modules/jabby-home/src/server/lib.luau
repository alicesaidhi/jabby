local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local jabby_core = require(script.Parent.Parent.Parent.roblox_packages.jabby_core)
local jabby_types = require(script.Parent.Parent.Parent.roblox_packages.jabby_types)
local net = require(script.Parent.Parent.net)

local registered_applets = jabby_core.active_applets

return function(applet: jabby_types.JabbyApplet<any>)
	local active_sockets = {}

	net.get_registered_applets:connect(0):on_invoke(function(sender, _)
		local socket, socket_id = net.communicate_frame_time:open_socket(sender)
		active_sockets[socket] = true

		local applets = {}

		for idx, applet in registered_applets do
			applets[idx] = {
				name = applet.name,
				description = applet.description,
				id = applet.unique_id,
				client = applet.client
			}
		end
		
		return {
			socket = socket_id,
			applets = applets
		}
	end)

	RunService.Heartbeat:Connect(function()
		for socket in active_sockets do
			if socket:status() == "closed" then active_sockets[socket] = false; continue end
			socket:send({
				heartbeattime = Stats.HeartbeatTime,
				rendergputime = Stats.RenderGPUFrameTime,
				rendercputime = Stats.RenderCPUFrameTime,
				memory = Stats:GetTotalMemoryUsageMb() * 1000 * 1000
			})
		end
	end)

	if RunService:IsClient() then
		jabby_core.open_client(applet, { id = 0, to = Players.LocalPlayer })
	end

end