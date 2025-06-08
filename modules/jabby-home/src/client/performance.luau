local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local jabby_types = require(script.Parent.Parent.Parent.roblox_packages.jabby_types)
local jabby_ui = require(script.Parent.Parent.Parent.roblox_packages.jabby_ui)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local net = require(script.Parent.Parent.net)

local source = vide.source
local cleanup = vide.cleanup

local function convert_units(unit: string, value: number): (string)
	assert(typeof(value) == "number", value)
	local s = math.sign(value)
	value = math.abs(value)
    local prefixes = {
        [4] = "T",
        [3] ="G",
        [2] ="M",
        [1] = "k",
        [0] = "",
        [-1] = "m",
        [-2] = "u",
        [-3] = "n",
        [-4] = "p"
    }

    local order = 0
    
    while value >= 1000 do
        order += 1
        value /= 1000
    end

    while value ~= 0 and value < 1 do
        order -= 1
        value *= 1000
    end

	local format = "%.01f"
    if value >= 100 then
		format = "%.01f"
        value = math.floor(value)
    elseif value >= 10 then
		format = "%.01f"
        value = math.floor(value * 1e1) / 1e1
    elseif value >= 1 then
		format = "%.02f"
        value = math.floor(value * 1e2) / 1e2
    end

    return string.format(format, value * s) .. prefixes[math.clamp(order, -4, 4)] .. unit
end

local function performance()
		
	local store = vide.source({} :: { [jabby_types.Host]: {
		memory: vide.Source<number>,
		heartbeat_time: vide.Source<number>,
		render_gpu_time: vide.Source<number>,
		render_cpu_time: vide.Source<number>,
	} })
	local open_connections = {}

	local function obtain_store_data(host: jabby_types.Host)
		local data = net.get_performance_socket:invoke({ to = host, id = 0 }, nil)
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
			}
			store(store())

			local socket = net.communicate_frame_time:accept_socket(host, result.value.socket)
			socket:on_event(function(packet)
				heartbeat_time(buffer.readf32(packet, 0))
				render_gpu_time(buffer.readf32(packet, 4))
				render_cpu_time(buffer.readf32(packet, 8))
				memory(buffer.readf32(packet, 12))

			end)

			open_connections[host] = socket
		end)
	end

	for _, player in Players:GetPlayers() do
		obtain_store_data(player)
	end
	obtain_store_data("server")
	
	cleanup(function()
		for host, socket in open_connections do
			socket:close()
		end
	end)
	cleanup(Players.PlayerAdded:Connect(obtain_store_data))
	cleanup(RunService.Heartbeat:Connect(function()
		for host, socket in open_connections do
			if socket:status() ~= "closed" then continue end
			store()[host] = nil
			store(store())
		end
	end))

	local hosts = source({ "Host" } :: { string })
	local memory_usage = source({ "Memory Usage" } :: { number })
	local heartbeat_time = source({ "CPU" } :: { number })
	local render_gpu_time = source({ "GPU" } :: { number })
	local render_cpu_time = source({ "CPU Render" } :: { number })
	
	cleanup(RunService.Heartbeat:Connect(function(dt)
		local idx = 2
		for host, data in store() do
			hosts()[idx] = tostring(host)
			memory_usage()[idx] = data.memory()
			heartbeat_time()[idx] = data.heartbeat_time()
			render_gpu_time()[idx] = data.render_gpu_time()
			render_cpu_time()[idx] = data.render_cpu_time()
			idx += 1
		end

		table.move({}, #hosts(), idx, idx, hosts())
		table.move({}, #memory_usage(), idx, idx, memory_usage())
		table.move({}, #heartbeat_time(), idx, idx, heartbeat_time())
		table.move({}, #render_gpu_time(), idx, idx, render_gpu_time())
		table.move({}, #render_cpu_time(), idx, idx, render_cpu_time())

		hosts(hosts())
		memory_usage(memory_usage())
		heartbeat_time(heartbeat_time())
		render_gpu_time(render_gpu_time())
		render_cpu_time(render_cpu_time())
	end))
	
	return jabby_ui.container {
		ws = 1, hs = 1,
		flex = { pad = 8, justify = "fill" }, pad = { p = 4 },

		(jabby_ui.tablesheet :: any) {
			ws = 1, hs = 1,
			
			use_offset = source { 60 },
			columns = function()
				return { hosts, memory_usage, heartbeat_time, render_gpu_time, render_cpu_time } :: { () -> { any } }
			end,

			enable_sort_key = true,
			auto_sort = true,

			header = function(value)
				return jabby_ui.container {
					name = "Header",
					ws = 1, hs = 1, clips = true, auto = "",
					flex = { align = "center" },
					pad = { x = 4 },

					jabby_ui.text {
						ws = 1, auto = "",

						xalign = "left",
						text = value or "",
						weight = 700,
						
						{ TextTruncate = Enum.TextTruncate.AtEnd }
					}
				}
			end,
			field = function(value: () -> any, column: number, row: () -> number)
				return jabby_ui.container {
					ws = 1, hs = 1, clips = true, auto = "",
					flex = { align = "center" },
					pad = { x = 8 },

					jabby_ui.text {
						ws = 1, auto = "",

						font = if column == 1 then nil else jabby_ui.theme.mono,
						xalign = "left",
						text = function(): string
							return if column == 1 then value() or ""
								elseif column == 2 then convert_units("B", value() or 0)
								else convert_units("s", value() or 0)
						end
					}
				}
			end

		},

	}
end

return function()
	return jabby_ui.widget.widget {
		title = source("Performance"),
		w = 300, h = 300,
		min_w = 200, min_h = 200,

		fn = performance
	}
end