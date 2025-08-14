--!nonstrict
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local render = require(script.Parent.Parent.components.widget.render)
local state = require(script.Parent.Parent.components.widget.state)
local text = require(ReplicatedStorage.src.components.text)
local ui_labs = require(script.Parent.Parent.Parent.roblox_packages.ui_labs)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local widget = require(script.Parent.Parent.components.widget)

local source = vide.source

return ui_labs.CreateVideStory({
	vide = vide,
	controls = {
		enable_ui = true,
	},
}, function(props)
	vide.effect(function() state.enable_ui(props.controls.enable_ui()) end)

	local tabs = widget.horizontal {
		x = 32,
		y = 32,

		widget.tabs {
			widget.widget {
				title = source "Widget 1",
				w = 200,
				h = 200,
				min_w = 150,
				min_h = 150,

				fn = function()
					return text {
						pad = { x = 8 },
						text = "Hello World!",
					}
				end,
			},
		},

		widget.vertical {
			x = 32,
			y = 32,

			widget.tabs {
				widget.widget {
					title = source "Widget 2",
					w = 200,
					h = 200,
					min_w = 150,
					min_h = 150,

					fn = function()
						return text {
							pad = { x = 8 },
							text = "This is a test!",
						}
					end,
				},
			},

			widget.tabs {
				widget.widget {
					title = source "Widget 3",
					w = 200,
					h = 200,
					min_w = 150,
					min_h = 150,

					fn = function()
						return text {
							pad = { x = 8 },
							text = "yay!",
						}
					end,
				},
			},
		},
	}

	widget.root {
		tabs,
	}

	return render()
end)
