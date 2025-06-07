local RunService = game:GetService("RunService")

local jabby_types = require(script.Parent.Parent.Parent.roblox_packages.jabby_types)
local jabby_ui = require(script.Parent.Parent.Parent.roblox_packages.jabby_ui)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)

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

local function performance(applets: () -> { [jabby_types.Host]: {
	memory: vide.Source<number>,
	heartbeat_time: vide.Source<number>,
	render_gpu_time: vide.Source<number>,
	render_cpu_time: vide.Source<number>,
} })
	return function()
		local hosts = source({ "Host" } :: { string })
		local memory_usage = source({ "Memory Usage" } :: { number })
		local heartbeat_time = source({ "CPU" } :: { number })
		local render_gpu_time = source({ "GPU" } :: { number })
		local render_cpu_time = source({ "CPU Render" } :: { number })
		
		cleanup(RunService.Heartbeat:Connect(function(dt)
			local idx = 2
			for host, data in applets() do
				hosts()[idx] = tostring(host)
				memory_usage()[idx] = data.memory()
				heartbeat_time()[idx] = data.heartbeat_time()
				render_gpu_time()[idx] = data.render_gpu_time()
				render_cpu_time()[idx] = data.render_cpu_time()
				idx += 1
			end

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
end

return function(applets: () -> { [jabby_types.Host]: { ms: number } })
	return jabby_ui.widget.widget {
		title = source("Performance"),
		w = 300, h = 300,
		min_w = 200, min_h = 200,

		fn = performance(applets)
	}
end