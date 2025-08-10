local jabby_query_parser = require(script.Parent.Parent.Parent.Parent.roblox_packages.jabby_query_parser)
local jabby_types = require(script.Parent.Parent.Parent.Parent.roblox_packages.jabby_types)
local jabby_ui = require(script.Parent.Parent.Parent.Parent.roblox_packages.jabby_ui)
local jabby_util = require(script.Parent.Parent.Parent.Parent.roblox_packages.jabby_util)
local vide = require(script.Parent.Parent.Parent.Parent.roblox_packages.vide)
local net = require(script.Parent.Parent.Parent.net)
local entity_editor = require(script.Parent.entity_editor)

local source = vide.source
local effect = vide.effect
local cleanup = vide.cleanup
local untrack = vide.untrack
local show = vide.show

local function ecs_registry(target: jabby_types.Target)

	local await_capabilities = net.obtain_world_capabilities:invoke(target)
	local ok, pending = source(false), source(true)
	local capabilities

	local issues = source({} :: { jabby_query_parser.Issue })
	local query_ok = source(true :: true | string)
	
	local check = source("")
	local query = source("")
	local columns = source {
		source { "id" },
		source { "" }
	}

	local entities = source(0)
	local time_taken = source(0)

	local from = source(1)
	local upto = source(40)
	local live = source(true)

	-- clears all values inside the columns, but not the headers
	local function clear_values()
		columns()[1]({ "id" })
		for i = 2, #columns() do
			local column = columns()[i]
			column({ column()[1] })
		end
	end

	local function on_success(result: typeof(net.query_world._RECEIVE))
		assert(result.ok, "triggered on_success while not ok")
		assert(result.value.ok, "triggered on_success while not ok")

		local update_settings = net.update_settings:accept_socket(target.to, result.value.update_settings)
		local update_query_data = net.update_query_data:accept_socket(target.to, result.value.update_query_data)
		local update_value = net.update_value:accept_socket(target.to, result.value.update_value)		

		local column_fields = { source({ "id" }), source { "" } }
		for idx, cname in result.value.components do
			column_fields[idx + 1] = source { cname }
		end

		columns(column_fields)
		entities(0)
		time_taken(0)
		query_ok(true :: true)
		
		cleanup(function()
			untrack(clear_values)
			update_settings:close()
			update_query_data:close()
			update_value:close()
		end)

		effect(function()
			untrack(clear_values)
			update_settings:send({
				from = from(),
				upto = upto(),
				live = live()
			})
		end)

		update_query_data:on_event(function(value)
			if value.entities ~= nil then entities(value.entities) end
			if value.time_taken ~= nil then time_taken(value.time_taken) end
			if value.valid == true then
				query_ok(true :: true)
			elseif typeof(value.valid) == "string" then
				query_ok(value.valid)
			end
		end)

		update_value:on_event(function(value)
			if update_value:status() == "closed" then return end
			local column = column_fields[value.column]
			if not column then error("no column assigned before-hand") end
			column()[value.row + 1] = value.value
			column(column())
		end)
	end

	-- queries the world with the given input
	local function query_world()
		untrack(clear_values)

		local destroyed = false
		local scope
		local initial_input = query()
		local yield = net.query_world:invoke(target, initial_input)
		yield:after(function(result)
			if not result.ok then return warn(result.why) end
			if result.value.ok == false then
				if query() ~= initial_input then return end
				issues(result.value.issues)
			else
				local destroy = vide.root(function()
					on_success(result)
				end)

				if destroyed then destroy() end
				scope = destroy
			end
		end)
		
		cleanup(function()
			if scope then scope() end
			destroyed = true
		end)
	end

	effect(function()
		local should_check_for = check()
		local _, result = pcall(jabby_query_parser.values, should_check_for, {
			features = {
				enable_relationships = if capabilities then capabilities.has_relationships else false,
				enable_excludes = if capabilities then capabilities.has_exclude else false,
				enable_wildcard = if capabilities then capabilities.has_wildcard_relationships else false,
				enable_only_excludes = if capabilities then capabilities.exclude_only else false
			}
		})
		issues(result.issues)
		
		net.check_result:invoke(target, should_check_for):after(function(result)
			if not result.ok then return end
			if check() ~= should_check_for then return end
			issues(result.value)
		end)
	end)

	-- updates the query results whenever a new query is made
	effect(query_world)
	
	-- obtains the capabilities of the subject registry, which is necessary for
	-- the parser.
	await_capabilities:after(function(result)
		ok(result.ok)
		pending(false)

		if result.ok then
			capabilities = result.value
		end
	end)
	
	return jabby_ui.container {
		ws = 1, hs = 1,
		flex = { align = "between", pad = 4 },

		jabby_ui.container {
			name = "Input",
			ws = 1, auto = "y", pad = { p = 8 },
			flex = { justify = "between", pad = 4 },
			
			jabby_ui.textfield {
				ws = 1, hs = 1, grow = 1, shrink = 1,
				placeholder = `include, "two words", !exclude, $id, #tag, (relation, ship)`,

				error = function()
					return #issues() > 0
				end,

				oninput = check :: (string) -> (),
				enter = query :: (string) -> (),
			},

			show(function()
				return #issues() > 0
			end, function()
				return jabby_ui.text {
					xalign = "left", wraps = true,
					font = jabby_ui.theme.mono,

					text = function()
						local values = {}
						for _, issue in issues() do
							table.insert(values, `{issue.why} from {issue.span.x} to {issue.span.y}`)
						end
						return table.concat(values, "\n")
					end,
				}
			end)
		},

		jabby_ui.tablesheet({
			ws = 1, grow = 1, shrink = 1,
			disable_top_corners = true,

			min_sizes = source { 24 },
			use_offset = source { 32 } :: () -> { number },

			columns = columns :: () -> { () -> { string } },

			field = function(value: () -> any, column: number, row: () -> number): Instance
				return jabby_ui.container {
					ws = 1, hs = 1, clips = true, auto = "",
					flex = { align = "center" },
					pad = { x = function() return if jabby_ui.theme.compact() then 5 else 8 end },

					jabby_ui.text {
						ws = 1, auto = "",

						font = if column == 1 then nil else jabby_ui.theme.mono,
						xalign = "left",
						text = function()
							local v = value()
							return tostring(if v == nil then "" else value())
						end
					},

					jabby_ui.context_menu {
						{ kind = "action" :: "action", text = "Edit Entity", clicked = function()
							jabby_ui.widget.root {
								jabby_ui.widget.tabs {
									entity_editor {
										target = target,
										entity = columns()[1]()[row()]
									}
								}
							}
							
						end } :: any,
						
						{ kind = "action", text = "Edit Component", clicked = function()
							print("hello")
						end },
							
						{ kind = "action", text = "Track Entity", clicked = function()
							print("hello")
						end },
					}
				}
			end,

			jabby_ui.container {
				ws = 1, hs = 1, clips = true,
				pad = { x = 4, y = 2 }, flex = { direction = "row", justify = "left", pad = 6 },

				jabby_ui.button {
					ws = 0, w = 20, h = 16, size = 16, auto = "",
					text = "<",

					enabled = function()
						local delta = upto() - from() + 1
						return from() - delta > 0
					end,

					clicked = function()
						local delta = upto() - from() + 1
						upto(upto() - delta)
						from(from() - delta)
					end
				},
				jabby_ui.button {
					ws = 0, w = 20, h = 16, size = 16, auto = "",
					text = ">",

					enabled = function()
						local delta = upto() - from() + 1
						return from() + delta <= entities()
					end,

					clicked = function()
						local delta = upto() - from() + 1
						upto(upto() + delta)
						from(from() + delta)
					end
				},

				jabby_ui.textfield {
					w = 30, h = 18, size = 12,

					text = function()
						return tostring(from())
					end,

					enter = function(input: string)
						local n = tonumber(input)
						if n == nil then return end
						if n > upto() then return end
						
						from(n)
					end
				},
				
				jabby_ui.textfield {
					w = 30, h = 18, size = 12,

					text = function()
						return tostring(upto())
					end,

					enter = function(input: string)
						local n = tonumber(input)
						if n == nil then return end
						if n < from() then return end
						
						upto(n)
					end
				},
				
				jabby_ui.text {
					text = function()
						return `entities: {entities()}\ttakes: {jabby_util.convert_scale("s", time_taken())}`
					end
				},
			}
			
		} :: any)

	}
end

return function(target: jabby_types.Target)
	return jabby_ui.widget.widget {
		title = source("ECS Registry"),
		w = 300, h = 500,
		min_w = 200, min_h = 250,

		fn = function()
			return ecs_registry(target)
		end
	}
end