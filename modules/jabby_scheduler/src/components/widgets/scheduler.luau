local RunService = game:GetService "RunService"

local jabby_types =
	require(script.Parent.Parent.Parent.Parent.roblox_packages.jabby_types)
local jabby_ui =
	require(script.Parent.Parent.Parent.Parent.roblox_packages.jabby_ui)
local jabby_util =
	require(script.Parent.Parent.Parent.Parent.roblox_packages.jabby_util)
local net = require(script.Parent.Parent.Parent.net)
local vide = require(script.Parent.Parent.Parent.Parent.roblox_packages.vide)

local source = vide.source
local derive = vide.derive
local cleanup = vide.cleanup
local switch = vide.switch

local MAX_FRAMES_STORED = 150
local UPDATE_BARS = 1 / 60

local function average(values: { number }, sample: number)
	local n = 0
	for i = 1, math.min(#values, sample) do
		n += values[i]
	end
	return n / math.min(#values, sample)
end

local function median(values: { number }, sample: number)
	local sorted = { unpack(values, 1, sample) }
	table.sort(sorted)
	return sorted[#sorted // 2] or 0
end

local function interval<T>(t: number, fn: (number) -> T): () -> T
	local value = vide.source(fn(0))
	local accumulate = 0

	cleanup(RunService.PostSimulation:Connect(function(dt)
		accumulate += dt
		if accumulate > t then
			value(fn(accumulate))
			accumulate = 0
		end
	end))

	return value
end

type Source<T> = vide.Source<T>
type SystemData = {
	name: Source<string>,
	phase: Source<string>,
	paused: Source<boolean>,

	frame: Source<number>,
	time: Source<{ number }>,
	memory_pressure: Source<{ number }>,
}

local function ecs_scheduler(target: jabby_types.Target, title: (string) -> ())
	local systems = source({} :: { [number]: SystemData })
	local destroyed = false

	local function get_system_data(id: number)
		if systems()[id] ~= nil then return systems()[id] end

		local data = {
			name = source "NO NAME REGISTERED",
			phase = source "",
			paused = source(false),

			frame = source(0),
			time = source { 0 },
			memory_pressure = source { 0 },
		}
		systems()[id] = data
		systems(systems())
		return data
	end

	local function read_update_systems(input: buffer)
		for i = 0, buffer.len(input) - 1, 14 do
			local id = buffer.readu16(input, i + 0)
			local frame = buffer.readu32(input, i + 2)
			local t = buffer.readf32(input, i + 6)
			local allocations = buffer.readf32(input, i + 10)

			local system_data = get_system_data(id)
			if system_data.frame() < frame then system_data.frame(frame) end

			local idx = system_data.frame() - frame + 1
			if idx > MAX_FRAMES_STORED then continue end

			table.remove(system_data.memory_pressure(), MAX_FRAMES_STORED)
			table.remove(system_data.time(), MAX_FRAMES_STORED)
			table.insert(system_data.time(), idx, t)
			table.insert(system_data.memory_pressure(), idx, allocations)

			system_data.memory_pressure(system_data.memory_pressure())
			system_data.time(system_data.time())
		end
	end

	local update_system_state
	local update_system_frame
	local remove_system

	local function destroy()
		if not update_system_state then return end
		if not update_system_frame then return end
		if not remove_system then return end

		update_system_state:close()
		update_system_frame:close()
		remove_system:close()
	end

	net.watch_scheduler:invoke(target):after(function(data)
		if data.ok == false then return warn(data.why) end

		title(`Scheduler {data.value.name}`)

		update_system_state = net.update_system_state:accept_socket(
			target.to,
			data.value.update_system_data
		)
		update_system_frame = net.update_system_frame:accept_socket(
			target.to,
			data.value.update_system_frame
		)
		remove_system =
			net.remove_system:accept_socket(target.to, data.value.remove_system)

		if destroyed then return destroy() end

		update_system_state:on_event(function(data)
			local system = get_system_data(data.id)

			if data.name ~= nil then system.name(data.name) end
			if data.paused ~= nil then system.paused(data.paused) end
			if data.phase ~= nil then system.phase(data.phase) end
		end)

		update_system_frame:on_event(function(data)
			vide.batch(function() read_update_systems(data) end)
		end)

		remove_system:on_event(function(data)
			systems()[data.id] = nil
			systems(systems())
		end)
	end)

	cleanup(function()
		destroyed = true
		destroy()
	end)

	local highest_pressure = derive(function()
		local max = 0
		for _, system in systems() do
			max = math.max(
				max,
				average(system.memory_pressure(), MAX_FRAMES_STORED)
			)
		end
		return max
	end)

	local highest_time = derive(function()
		local max = 0
		for _, system in systems() do
			max = math.max(max, average(system.time(), MAX_FRAMES_STORED))
		end
		return max
	end)

	return jabby_ui.tablesheet {
		ws = 1,
		hs = 1,

		disable_top_corners = true,

		columns = source {
			derive(function()
				local names = { "Name" }

				for _, system in systems() do
					table.insert(names, system.name)
				end

				return names
			end),
			derive(function()
				local times = { "Time" }

				for _, system in systems() do
					table.insert(times, system.time)
				end

				return times
			end),
			derive(function()
				local presssure = { "Allocations" }

				for _, system in systems() do
					table.insert(presssure, system.memory_pressure)
				end

				return presssure
			end),
		},

		enable_sort_key = true,
		auto_sort = true,
		get_value = function(value)
			local v = value()
			return if typeof(v) == "table"
				then median(v, MAX_FRAMES_STORED)
				else v
		end,

		field = function(value: () -> any, column: number, row: () -> number)
			return jabby_ui.container {
				ws = 1,
				hs = 1,
				clips = true,
				auto = "",
				flex = {
					direction = "row",
					align = "center",
					justify = "between",
					pad = 6,
				},
				pad = { x = 8 },

				switch(source(column)) {
					[1] = function()
						return jabby_ui.text {
							ws = 1,
							auto = "",

							xalign = "left",
							text = function() return value()() end,
						}
					end,

					[2] = function()
						return {
							jabby_ui.text {
								w = 60,
								auto = "xy",

								font = jabby_ui.theme.mono,
								xalign = "left",
								text = function()
									return jabby_util.convert_scale(
										"s",
										average(value()(), MAX_FRAMES_STORED)
									)
								end,
							},

							jabby_ui.container {
								h = 8,
								grow = 1,
								shrink = 1,

								jabby_ui.container {
									ws = interval(
										UPDATE_BARS,
										function()
											return average(
												value()(),
												MAX_FRAMES_STORED
											) / highest_time()
										end
									),
									hs = 1,

									color = jabby_ui.theme.bg_fg_low(-3),
								},
							},
						}
					end,

					[3] = function()
						return {
							jabby_ui.text {
								w = 60,
								auto = "xy",

								font = jabby_ui.theme.mono,
								xalign = "left",
								text = function()
									return jabby_util.convert_scale(
										"B",
										median(value()())
									)
								end,
							},

							jabby_ui.container {
								h = 8,
								grow = 1,
								shrink = 1,

								jabby_ui.container {
									ws = interval(
										UPDATE_BARS,
										function()
											return average(
												value()(),
												MAX_FRAMES_STORED
											) / highest_pressure()
										end
									),
									hs = 1,

									color = jabby_ui.theme.bg_fg_low(-3),
								},
							},
						}
					end,
				},
			}
		end,
	}
end

return function(target: jabby_types.Target)
	local title = vide.source "ECS Scheduler"
	return jabby_ui.widget.widget {
		title = title,
		w = 300,
		h = 500,
		min_w = 200,
		min_h = 250,

		fn = function() return ecs_scheduler(target, title) end,
	}
end
