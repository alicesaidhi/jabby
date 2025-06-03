--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local text = require(ReplicatedStorage.src.components.text)
local textfield = require(ReplicatedStorage.src.components.textfield)
local ui_labs = require(script.Parent.Parent.Parent.roblox_packages.ui_labs)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local button = require(script.Parent.Parent.components.button)
local container = require(script.Parent.Parent.components.container)
local expandable = require(script.Parent.Parent.components.expandable)
local theme = require(script.Parent.Parent.util.theme)

local source = vide.source
local effect = vide.effect

return ui_labs.CreateVideStory({
	vide = vide,
	controls = {
		enabled = true,
		compact = false,
		error = false,
		helper = ""
	}
}, function(props)
	local enabled = props.controls.enabled

	effect(function()
		theme.compact(props.controls.compact())
	end)

	local oninput = source("")
	local onenter = source("")
	local onfocuslost = source("")


	return container {
		ws = 1, hs = 1,
		flex = { justify = "center", align = "center", pad = 8 },
		
		textfield {
			w = 280, h = 0,

			monospace = true,
			error = props.controls.error,
			helper_text = props.controls.helper, 	
			text = 'A quick brown fox jumped over the lazy dog!',
			placeholder = "Placeholder...",

			enter = onenter,
			oninput = oninput,
			focuslost = onfocusllost
		},

		textfield {
			w = 280, h = 0,

			monospace = true,
			error = props.controls.error,
			helper_text = props.controls.helper, 	
			text = 'A quick brown fox jumped over the lazy dog!',
			placeholder = "Placeholder...",

			container {
				w = 24, h = 24,

				image = "rbxassetid://100188624502987",
			}
		},

		text {
			text = oninput
		},

		text {
			text = onenter
		},

		text {
			text = onfocuslost
		},

		
	}

end)
