local RunService = game:GetService "RunService"

local jabby_scheduler =
	require(script.Parent.Parent.Parent.roblox_packages.jabby_scheduler)
local jabby_types = require(
	script.Parent.Parent.Parent.Parent.jabby_core.roblox_packages.jabby_types
)

local net = jabby_scheduler.net

return function(applet: jabby_types.JabbyApplet<{}>)
	local id = applet.unique_id

	net.watch_scheduler:connect(id):on_invoke(function(target)
		local remove_system = net.remove_system:open_socket(target)
		local update_system_frame = net.update_system_frame:open_socket(target)
		local update_system_state = net.update_system_state:open_socket(target)

		local first = true
		local n = 0
		RunService.Heartbeat:Connect(function(dt)
			if update_system_state:status() ~= "open" then return end

			local start = gcinfo()
			if first then
				update_system_state:send {
					id = 1,

					name = "heartbeat",
					phase = "runservice",
					paused = false,
				}
				update_system_state:send {
					id = 2,

					name = "sines",
					phase = "runservice",
					paused = false,
				}
				update_system_state:send {
					id = 3,

					name = "sines",
					phase = "runservice",
					paused = false,
				}
				update_system_state:send {
					id = 6,

					name = "heartbeat",
					phase = "runservice",
					paused = false,
				}
				update_system_state:send {
					id = 4,

					name = "heartbeat",
					phase = "runservice",
					paused = false,
				}
				update_system_state:send {
					id = 8,

					name = "bleh",
					phase = "runservice",
					paused = false,
				}
				update_system_state:send {
					id = 5,

					name = "sines",
					phase = "runservice",
					paused = false,
				}
				update_system_state:send {
					id = 7,

					name = "bleh",
					phase = "runservice",
					paused = false,
				}
			end

			local s = os.clock()
			for i = 1, 100000 do
				math.sin(i)
				local useless = {}
			end
			local t = os.clock() - s

			local b = buffer.create(28)
			local finish = gcinfo()
			buffer.writeu16(b, 0, 1)
			buffer.writeu32(b, 2, n)
			buffer.writef32(b, 6, dt)
			buffer.writef32(b, 10, (finish - start) * 1000)
			buffer.writeu16(b, 14 + 0, 2)
			buffer.writeu32(b, 14 + 2, n)
			buffer.writef32(b, 14 + 6, t)
			buffer.writef32(b, 14 + 10, finish - start)
			update_system_frame:send(b)

			first = false
		end)

		return {
			name = "test",

			remove_system = remove_system.socket_id,
			update_system_frame = update_system_frame.socket_id,
			update_system_data = update_system_state.socket_id,
		}
	end)
end
