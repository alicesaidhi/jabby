local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local jabby_core = require(script.Parent.Parent.Parent.roblox_packages.jabby_core)
local jabby_types = require(script.Parent.Parent.Parent.roblox_packages.jabby_types)
local net = require(script.Parent.Parent.net)

local registered_applets = jabby_core.active_applets

local SEND_EVERY = 0.5

return function(applet: jabby_types.JabbyApplet<any>)
	local active_sockets = {}

	net.get_registered_applets:connect(0):on_invoke(function(sender, _)
		local applets = {}

		for idx, applet in registered_applets do
			applets[idx] = {
				name = applet.name,
				description = applet.description,
				id = applet.unique_id,
				client = applet.client
			}
		end
		
		return applets
	end)

	net.get_performance_socket:connect(0):on_invoke(function(sender, _)
		local socket, socket_id = net.communicate_frame_time:open_socket(sender)
		active_sockets[socket] = true

		return {
			socket = socket_id,
		}
	end)

	local average_heartbeat = 0
	local render_gpu_frame_time = 0
	local render_cpu_frame_time = 0
	local counter = 0
	local acccumulate = 0

	RunService.Heartbeat:Connect(function(dt)
		counter += 1
		acccumulate += dt

		average_heartbeat += Stats.HeartbeatTime
		render_gpu_frame_time += Stats.RenderGPUFrameTime
		render_cpu_frame_time += Stats.RenderCPUFrameTime

		if acccumulate > SEND_EVERY then
			for socket in active_sockets do
				if socket:status() == "closed" then
					active_sockets[socket] = nil
					continue
				end

				local b = buffer.create(16)
				buffer.writef32(b, 0, average_heartbeat / counter)
				buffer.writef32(b, 4, render_gpu_frame_time / counter)
				buffer.writef32(b, 8, render_cpu_frame_time / counter)
				buffer.writef32(b, 12, Stats:GetTotalMemoryUsageMb() * 1000 * 1000)
				
				socket:send(b)
			end

			average_heartbeat = 0
			render_gpu_frame_time = 0
			render_cpu_frame_time = 0
			acccumulate -= SEND_EVERY
			counter = 0
		end
	end)

	if RunService:IsClient() then
		jabby_core.open_client(applet, { id = 0, to = Players.LocalPlayer })
	end

end