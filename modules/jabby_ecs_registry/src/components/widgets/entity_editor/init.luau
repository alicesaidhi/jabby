local source = require(script.Parent.Parent.Parent.Parent.Parent["_foreign_alicesaidhi+vide"]["0.4.1-testing.4"].vide.src.source)
local jabby_types = require(script.Parent.Parent.Parent.Parent.roblox_packages.jabby_types)
local jabby_ui = require(script.Parent.Parent.Parent.Parent.roblox_packages.jabby_ui)
local vide = require(script.Parent.Parent.Parent.Parent.roblox_packages.vide)
local net = require(script.Parent.Parent.Parent.net)
local component_column = require(script.component_column)

local source = vide.source
local derive = vide.derive
local cleanup = vide.cleanup
local effect = vide.effect
local changed = vide.changed

type EditData = {
	tag: boolean,
	value: nil
} | {
	tag: nil,
	value: string
} | {
	tag: nil,
	value: nil
}

type props = {
	title: (string) -> (),
	entity: string,
	target: jabby_types.Target,

	component: string?
}

local function entity_editor(p: props)
	local is_ok = source(false)
	local is_pending = source(true)

	local live_updates = source(true)
	local result = net.get_entity_info:invoke(p.target, {
		entity = p.entity
	})

	local tags = source({} :: { [string]: boolean })
	local components = source({} :: { [string]: string })
	local update_entity_components = nil :: typeof(net.update_entity_components:accept_socket("server", 0))?
	local update_tracking_settings = nil :: typeof(net.update_tracking_settings:accept_socket("server", 0))?
	local destroyed = false

	local editing_component = source(false :: false | string)
	local edited_data: vide.Source<{ [string]: EditData }> = source {}
	local editing = source(false :: false | string)

	local component_columns = derive(function()
		local keys = {"Component"}
		local values = {"Value"}

		for key, value in components() do
			table.insert(keys, key)
			table.insert(values, value)
		end

		for key, value in edited_data() do
			if value.tag then continue end
			if value.value == nil then continue end
			if components()[key] then continue end
			
			table.insert(keys, key)
			table.insert(values, value.value)
		end

		if editing_component() ~= false then
			table.insert(keys, editing_component())
			table.insert(values, "")
		end

		return {
			function() return keys end,
			function() return values end
		}
	end)

	local tag_columns = derive(function()
		local keys = { "Tags" }

		for tag in tags() do
			table.insert(keys, tag)
		end

		for key, value in edited_data() do
			if value.tag == nil then continue end
			if tags()[key] then continue end
			
			table.insert(keys, key)
		end
		
		return { function() return keys end }
	end)

	cleanup(function()
		destroyed = true
		if update_entity_components then update_entity_components:close() end
		if update_tracking_settings then update_tracking_settings:close() end
	end)

	result:after(function(value)
		if not value.ok or not value.value.is_valid then
			is_pending(false)
			is_ok(false)
			return
		end

		if destroyed then
			return
		end

		update_entity_components = net.update_entity_components:accept_socket(
			p.target.to,
			value.value.update_entity_components
		)
		update_tracking_settings = net.update_tracking_settings:accept_socket(
			p.target.to,
			value.value.update_tracking_settings
		)

		assert(update_entity_components)

		update_tracking_settings:send({
			live_updates = live_updates(),
			refresh = false
		})

		update_entity_components:on_event(function(packet)
			components()[packet.component] = packet.value
			components(components())

			if packet.tag then
				tags()[packet.component] = true
				tags(tags())
			elseif tags()[packet.component] then
				tags()[packet.component] = nil
				tags(tags())
			end
		end)
	end)

	local refreshed = true
	local refresh = source(os.clock())
	effect(function()
		refresh()
		local packet = {
			live_updates = live_updates(),
			refresh = refreshed
		}

		if update_tracking_settings == nil then return end
		refreshed = false
		update_tracking_settings:send(packet)
	end)

	effect(function()
		p.title(`Edit Entity - {p.entity}`)
	end)

	local component_addition_text = source("")

	local window_absolute_position = source(Vector2.zero)
	local target_canvas_position = source(0)
	local absolute_position_properties = {} :: { [string]: vide.Source<Vector2> }

	local function scroll_to(property: string)
		local position = absolute_position_properties[property]
		if not position then return end
		local scroll_y = window_absolute_position().Y
		local y_offset = position().Y

		local canvas_offset = y_offset - scroll_y
		target_canvas_position(canvas_offset)
	end

	return jabby_ui.container {
		ws = 1, hs = 1,
		flex = { align = "between" },

		jabby_ui.container {
			ws = 1, hs = 0, auto = "y",
			pad = { p = 4 },
			flex = { direction = "row", justify = "between", pad = 4, wrap = true },

			vide.show(function()
				return not live_updates()
			end, function()
				return jabby_ui.button {
					grow = 1,
					w = 28, h = 28,
					pad = { x = 6 },
					flex = { direction = "row", pad = 8 },
					order = -1,

					text = "R",

					clicked = function()
						refreshed = true
						refresh(os.clock())
					end,
				}
			end),

			jabby_ui.button {
				grow = 1,
				w = 125, h = 28,
				pad = { x = 6 },
				flex = { direction = "row", pad = 8 },

				text = "Live Properties",

				clicked = function()
					live_updates(not live_updates())
				end,

				jabby_ui.checkbox {
					checked = live_updates,
				}
			},
			
			jabby_ui.button {
				grow = 1,
				pad = { x = 6 },
				w = 100, h = 28,

				flex = { direction = "row" },
				text = "Apply Updates",
				enabled = function()
					return next(edited_data()) ~= nil
				end,

				clicked = function()
					net.edit_entity:invoke(p.target, {
						entity = p.entity,
						components = edited_data()
					}):after(function(value)
						print(value)
					end)
					edited_data({})
				end
			},
			
			jabby_ui.button {
				grow = 1,
				pad = { x = 6 },
				w = 100, h = 28,

				flex = { direction = "row" },
				text = "Clear Updates",
				enabled = function()
					return next(edited_data()) ~= nil
				end,

				clicked = function()
					table.clear(edited_data())
					edited_data(edited_data())
				end
			},
		},

		jabby_ui.scroll_container {
			ws = 1, grow = 1, shrink = 1,
			flex = { align = "top" },
			cy = target_canvas_position,
			cauto = "y",

			y = target_canvas_position,
			
			jabby_ui.properties {
				ws = 1, hs = 0,
				disable_top_corners = true,
				min_sizes = source { 0.1 },
				use_offset = source { 70 },

				columns = component_columns,

				field = function(value: () -> any, column: number, row: () -> number): Instance
					local absolute_position = source(Vector2.zero)

					local function component()
						return component_columns()[1]()[row()]
					end

					local is_editing = function()
						return editing() == component() and column ~= 1
					end

					effect(function()
						if column ~= 1 then return end
						local name = component()
						if name == nil then return end
						absolute_position_properties[name] = absolute_position
						cleanup(function()
							absolute_position_properties[name] = nil
						end)
					end)

					return component_column {
						can_edit = column ~= 1,
						editing = is_editing,
						state = derive(function(): "added" | "edited" | "none" | "removed"
							local data = edited_data()[component()]
							local state = if data and not components()[component()] then "added"
								elseif data and data.value == nil and data.tag == nil and components()[component()] then "removed"
								elseif data and data.value then "edited"
								else "none"
							-- print(data, state)
							return state
						end),
						value = function()
							local base = value() or ""
							if edited_data()[component()] and column == 2 then
								return edited_data()[component()].value or ""
							end
							return base
						end,
						get_true_value = function()
							local base = value() or ""
							if edited_data()[component()] then
								return edited_data()[component()].value or base :: any
							end

							local result = net.get_entity_component:invoke(p.target, {
								entity = p.entity,
								component = component()
							}):await()

							if not result.ok then return base end
							local value = result.value
							if not value.exists then return base end
							if value.is_tag then return base end

							return value.component
						end,
						edit_value = function()
							if column == 1 then return end
							editing(component())
						end,
						set_value = function(text: string)
							editing(false :: false)
							if text == ("" :: any) then
								if components()[component()] then
									edited_data()[component()] = {
										value = nil,
										tag = nil,
									}
									editing_component(false :: false)
									edited_data(edited_data())
								else
									edited_data()[component()] = nil
									editing_component(false :: false)
									edited_data(edited_data())
								end
								return
							end

							edited_data()[component()] = {
								value = text,
								tag = nil
							}
							edited_data(edited_data())
							editing_component(false :: false)
						end,
						lose_focus = function(text)
							editing(false :: false)
							editing_component(false :: false)
						end,

						changed("AbsolutePosition", absolute_position)
					}
				end,

				final = jabby_ui.textfield {
					ws = 1, xs = 0, anchor = { 0, 0 },
					auto = "y", nocorner = true,

					placeholder = "Add Component",
					text = component_addition_text,

					focuslost = function(text: string, enter)
						component_addition_text(text)

						if not enter then return end

						-- we need to get information about the component first.
						-- if its a tag, we need to add it as a tag
						local result = net.get_entity_component:invoke(p.target, {
							entity = p.entity,
							component = text
						}):await()

						if not result.ok then
							task.defer(component_addition_text, "")
							return
						end

						if result.value.exists then
							task.defer(component_addition_text, "")

							if result.value.is_tag then
								edited_data()[result.value.name] = {
									tag = true,
									value = nil
								}
								edited_data(edited_data())
								scroll_to(result.value.name)
								return
							end

							editing(result.value.name)
							scroll_to(result.value.name)
							return
						elseif result.value.is_valid then
							task.defer(component_addition_text, "")

							if result.value.is_tag then
								edited_data()[result.value.name] = {
									tag = true,
									value = nil
								}
								edited_data(edited_data())
								scroll_to(result.value.name)
								return
							end
							
							editing_component(result.value.name)
							editing(result.value.name)
							scroll_to(result.value.name)
							return
						end
					end
				}
			},

			jabby_ui.properties {
				ws = 1, hs = 0,
				disable_top_corners = true,

				columns = tag_columns,

				field = function(value: () -> any, column: number, row: () -> number): Instance
					local absolute_position = source(Vector2.zero)
					
					effect(function()
						if column ~= 1 then return end
						local name = value()
						if not name then return end
						absolute_position_properties[name] = absolute_position
						cleanup(function()
							absolute_position_properties[name] = nil
						end)
					end)

					local function state(): "added" | "removed" | "none"
						local data = edited_data()[value()]
						local exists = tags()[value()]
						
						return
							if data and data.tag then "added"
							elseif exists and data and not data.tag then "removed"
							else "none"
					end

					return jabby_ui.container {
						ws = 1, clips = true, auto = "y",
						flex = { align = "center" },
						pad = { x = 5, y = 3 },
						
						color = function(): Color3
							local state = state()
							return
								if state == "added" then jabby_ui.theme.suc(0)()
								elseif state == "removed" then jabby_ui.theme.err(0)()
								else jabby_ui.theme.bg(0)()
						end,

						transparency = function()
							return if state() == "none" then 1 else 0.8
						end,

						jabby_ui.text {
							ws = 1, auto = "y",

							font = if column == 1 then nil else jabby_ui.theme.mono,
							xalign = "left",
							text = function()
								local v = value()
								return tostring(if v == nil then "" else value())
							end
						},

						clicked = function()
							local data = edited_data()[value()]
							local exists = tags()[value()]

							if exists and (not data or data.tag) then
								edited_data()[value()] = {
									tag = nil, value = nil
								}
								edited_data(edited_data())
							elseif data and not data.tag then
								edited_data()[value()] = nil
								edited_data(edited_data())
							elseif not exists then
								edited_data()[value()] = nil
								edited_data(edited_data())
							end
						end,

						changed("AbsolutePosition", absolute_position)
					}
				end
			},

			changed("AbsolutePosition", window_absolute_position)
		}

	}
end

return function(p: props)
	local title = source("Edit Entity")
	return jabby_ui.widget.widget {
		title = title,
		w = 400, h = 500,
		min_w = 200, min_h = 200,

		fn = function()
			return entity_editor({
				title = title,

				entity = p.entity,
				target = p.target,
			})
		end
	}
end