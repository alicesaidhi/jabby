--!nonstrict
local button = require(script.Parent.Parent.components.button)
local container = require(script.Parent.Parent.components.container)
local context_menu = require(script.Parent.Parent.components.context_menu)
local theme = require(script.Parent.Parent.util.theme)
local ui_labs = require(script.Parent.Parent.Parent.roblox_packages.ui_labs)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)

local show = vide.show
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

	effect(function() theme.compact(props.controls.compact()) end)

	return container {
		ws = 1,
		hs = 1,
		flex = { justify = "center", align = "center" },

		show(accent, function()
			return button {
				acc = true,
				enabled = enabled,
				clicked = function() print "meow!" end,

				text = "A quick brown fox jumped over the lazy dog!",
			}
		end, function()
			return button {
				acc = false,
				enabled = enabled,
				clicked = function() print "mrow!" end,

				text = "A quick brown fox jumped over the lazy dog!",

				context_menu {
					{
						kind = "action",
						text = "Action 1",
						clicked = function() print "hello" end,
					},

					{
						kind = "action",
						text = "Action 2",
						clicked = function() print "hello" end,
					},

					{
						kind = "action",
						text = "Action 3",
						clicked = function() print "hello" end,
					},

					{
						kind = "action",
						text = "Action 4",
						clicked = function() print "hello" end,
					},
				},
			}
		end),
	}
end)
