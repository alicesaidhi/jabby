--!nonstrict
local ui_labs = require(script.Parent.Parent.Parent.roblox_packages.ui_labs)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local button = require(script.Parent.Parent.components.button)
local container = require(script.Parent.Parent.components.container)
local text = require(script.Parent.Parent.components.text)
local theme = require(script.Parent.Parent.util.theme)

local show = vide.show

return ui_labs.CreateVideStory({
	vide = vide,
	controls = {
		accent = false,
		enabled = true
	}
}, function(props)
	local accent = props.controls.accent
	local enabled = props.controls.enabled

	return container {
		ws = 1, hs = 1,
		flex = { justify = "center", align = "center" },
		
		text {
			text = "A quick brown fox jumped over the lazy dog!"
		}
	}

end)
