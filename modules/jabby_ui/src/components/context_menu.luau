local UserInputService = game:GetService "UserInputService"

local anim = require(script.Parent.Parent.util.anim)
local container = require(script.Parent.container)
local ignore = require(script.Parent.ignore)
local map = require(script.Parent.Parent.util.map)
local portal = require(script.Parent.portal)
local shadow = require(script.Parent.shadow)
local theme = require(script.Parent.Parent.util.theme)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)

local source = vide.source
local show = vide.show
local indexes = vide.indexes
local switch = vide.switch
local read = vide.read

type Can<T> = T | () -> T
type Action = {
	kind: "action",
	text: string,
	image: string?,
	enabled: (() -> boolean)?,
	clicked: () -> (),
}
-- type Expandable = { kind: "expand", text: string, image: string?, [number]: Action }
type Group = { kind: "group", [number]: Action }

local enabled_global

local function action(p: Action)
	local transparency = source(1)
	task.delay(0.5, transparency, 0)

	return button {
		w = 150,
		h = 18,
		auto = "",
		flex = { direction = "row", justify = "left" },
		stroke = false,

		text = p.text,
		size = 14,
		font = theme.alt_font,
		enabled = p.enabled,

		clicked = function(input)
			if enabled_global then enabled_global(false) end
			p.clicked(input)
		end,
		transparency = transparency,

		container {
			w = 16,
			h = 16,
			order = -1,
			image = p.image,
		},

		container {
			grow = 1,
			shrink = 1,
			order = 1,
		},
	}
end

local function group(p: Group)
	return container {
		ws = 1,
		hs = 0,
		auto = "xy",
		flex = { pad = 0 },

		container {
			w = 150,
			h = 1,
			anchor = { 0, 0 },
			order = -1,

			color = theme.bg(-1),
		},

		container {
			ws = 0,
			hs = 0,
			auto = "xy",
			flex = { pad = 1 },
			order = 0,

			map(
				{ unpack(p) },
				function(value: Action, key: unknown) return action(value) end
			),
		},

		container {
			w = 150,
			h = 1,
			anchor = { 0, 0 },
			order = 1,

			color = theme.bg(-1),
		},
	}
end
return function(
	p: { primary: boolean?, [number]: Action | Group } | () -> { Action | Group }
)
	local enabled = source(false :: false | Vector3)
	local hovering = source(false)

	return {

		ignore {
			container {
				ws = 1,
				hs = 1,

				clicked = if type(p) == "table" and p.primary
					then function(input: InputObject) enabled(input.Position) end
					else nil,

				rightclick = function(input: InputObject)
					enabled(input.Position)
				end,
			},
		},

		portal {
			inherit_layout = true,

			show(enabled, function(pos: () -> Vector3)
				enabled_global = enabled
				local transparency = source(1)
				task.defer(transparency, 0)

				return portal {
					inherit_layout = false,

					container {
						ws = 1,
						hs = 1,

						input = function(input: InputObject)
							if
								input.UserInputState
								~= Enum.UserInputState.Begin
							then
								return
							end
							enabled(false :: false)
						end,
					},

					container {
						z = 100,
						w = 150,
						h = 0,
						anchor = { 0, 0 },
						x = function() return pos().X end,
						y = function() return pos().Y end,
						auto = "xy",
						flex = { pad = 1 },
						pad = { p = 2 },

						color = theme.bg(2),
						stroke = theme.bg(-1),
						transparency = anim(transparency),
						corner = 6,

						hover = hovering :: (boolean) -> (),

						indexes(
							function()
								return { unpack(read(p)) } :: { Action | Group }
							end,
							function(value: () -> Action | Group)
								return switch(
									function() return value().kind end
								) {
									group = function()
										return group(value() :: Group)
									end,

									action = function()
										return action(value() :: Action)
									end,
								}
							end
						),
					},
				}
			end),
		},
	}
end
