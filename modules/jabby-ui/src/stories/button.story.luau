--!nonstrict
local ui_labs = require(script.Parent.Parent.Parent.roblox_packages.ui_labs)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local button = require(script.Parent.Parent.components.button)
local container = require(script.Parent.Parent.components.container)
local theme = require(script.Parent.Parent.util.theme)

return ui_labs.CreateVideStory({
	vide = vide,
	controls = {}
}, function()

	return container {
		ws = 1, hs = 1,
		flex = { justify = "center", align = "center" },
		
		button {
			clicked = function()
				print("okay!")
			end
		}
	}

end)
