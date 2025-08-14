--!nonstrict
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local button = require(script.Parent.Parent.components.button)
local container = require(script.Parent.Parent.components.container)
local expandable = require(script.Parent.Parent.components.expandable)
local ignore = require(script.Parent.Parent.components.ignore)
local text = require(ReplicatedStorage.src.components.text)
local textfield = require(ReplicatedStorage.src.components.textfield)
local theme = require(script.Parent.Parent.util.theme)
local ui_labs = require(script.Parent.Parent.Parent.roblox_packages.ui_labs)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)

local source = vide.source
local effect = vide.effect
local changed = vide.changed

return ui_labs.CreateVideStory({
	vide = vide,
	controls = {
		enabled = true,
		compact = false,
		error = false,
		helper = "",
	},
}, function(props)
	local enabled = props.controls.enabled

	effect(function() theme.compact(props.controls.compact()) end)

	local oninput = source ""
	local onenter = source ""
	local onfocuslost = source ""
	local raw_2d = source(Vector2.zero)
	local absolute_parent = source(Vector2.zero)

	return container {
		ws = 1,
		hs = 1,
		flex = { justify = "center", align = "center", pad = 8 },

		changed("AbsolutePosition", absolute_parent),

		textfield {
			w = 280,
			h = 0,

			monospace = true,
			error = props.controls.error,
			helper_text = props.controls.helper,
			text = "A quick brown fox jumped over the lazy dog!",
			placeholder = "Placeholder...",

			enter = onenter,
			oninput = oninput,
			focuslost = onfocusllost,
			cursor_position_2d = raw_2d,
		},

		textfield {
			w = 280,
			h = 0,

			monospace = true,
			error = props.controls.error,
			helper_text = props.controls.helper,
			text = "A quick brown fox jumped over the lazy dog!",
			placeholder = "Placeholder...",

			container {
				w = 24,
				h = 24,

				image = "rbxassetid://100188624502987",
			},
		},

		ignore {
			container {
				x = function() return raw_2d().X - absolute_parent().X end,
				y = function() return raw_2d().Y - absolute_parent().Y end,

				z = 1000,

				w = 32,
				h = 32,
				color = Color3.new(1, 1, 1),
				transparency = 0.5,
			},
		},

		text {
			text = oninput,
		},

		text {
			text = onenter,
		},

		text {
			text = onfocuslost,
		},
	}
end)
