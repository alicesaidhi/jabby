--!nonstrict
local button = require(script.Parent.Parent.components.button)
local checkbox = require(script.Parent.Parent.components.checkbox)
local container = require(script.Parent.Parent.components.container)
local divider = require(script.Parent.Parent.components.divider)
local text = require(script.Parent.Parent.components.text)
local theme = require(script.Parent.Parent.util.theme)
local ui_labs = require(script.Parent.Parent.Parent.roblox_packages.ui_labs)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)

local show = vide.show
local source = vide.source
local effect = vide.effect

return ui_labs.CreateVideStory({
	vide = vide,
	controls = {
		accent = false,
		enabled = true,
		compact = false,
	},
}, function(props)
	local accent = props.controls.accent
	local enabled = props.controls.enabled
	local checked = source(false)

	effect(function() theme.compact(props.controls.compact()) end)

	return container {
		ws = 1,
		hs = 1,
		flex = { justify = "center", align = "center" },

		show(accent, function()
			return button {
				acc = true,
				enabled = enabled,
				clicked = function() checked(not checked()) end,

				checkbox { checked = checked },
				text = "A quick brown fox jumped over the lazy dog!",
			}
		end, function()
			return button {
				acc = false,
				enabled = enabled,
				clicked = function() checked(not checked()) end,

				checkbox { checked = checked },
				text = "A quick brown fox jumped over the lazy dog!",
			}
		end),
	}
end)
