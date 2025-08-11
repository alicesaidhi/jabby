--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local cornered = require(ReplicatedStorage.src.components.cornered)
local ui_labs = require(script.Parent.Parent.Parent.roblox_packages.ui_labs)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local container = require(script.Parent.Parent.components.container)

return ui_labs.CreateVideStory({
	vide = vide,
	controls = {
		topleft = 16,
		topright = 16,
		bottomleft = 16,
		bottomright = 16
	}
}, function(props)

	return container {
		ws = 1, hs = 1,
		flex = { justify = "center", align = "center" },
		
		cornered {
			w = 500, h = 500,

			topleft = props.controls.topleft,
			topright = props.controls.topright,
			bottomleft = props.controls.bottomleft,
			bottomright = props.controls.bottomright,

			color = Color3.new(1, 1, 1)
		}
	}

end)
