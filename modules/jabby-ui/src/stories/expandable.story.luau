--!nonstrict
local ui_labs = require(script.Parent.Parent.Parent.roblox_packages.ui_labs)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local button = require(script.Parent.Parent.components.button)
local container = require(script.Parent.Parent.components.container)
local expandable = require(script.Parent.Parent.components.expandable)
local theme = require(script.Parent.Parent.util.theme)

local show = vide.show
local effect = vide.effect

return ui_labs.CreateVideStory({
	vide = vide,
	controls = {
		enabled = true,
		compact = false
	}
}, function(props)
	local enabled = props.controls.enabled

	effect(function()
		theme.compact(props.controls.compact())
	end)


	return container {
		ws = 1, hs = 1,
		flex = { justify = "center", align = "center" },
		
		container {
			ws = 1, h = 300,
			color = theme.bg(0),

			expandable {
				ws = 1,
				expanded = enabled,
				
				container {
					ws = 1, auto = "y",
					flex = {}, pad = { p = 16 },

					color = theme.bg(0.5),

					button {
						acc = true,
						enabled = enabled,
						clicked = function()
							print("meow!")
						end,

						text = "A quick brown fox jumped over the lazy dog!",
					}
				}

			}
		}
	}

end)
