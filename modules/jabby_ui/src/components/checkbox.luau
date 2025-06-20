local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local component = require(script.Parent.Parent.util.component)
local conditional = require(script.Parent.Parent.util.conditional)
local theme = require(script.Parent.Parent.util.theme)
local container = require(script.Parent.container)

local spring = vide.spring

type Can<T> = T | () -> T
return component(function(p: {
	checked: () -> boolean,
}, _)

	local checked = p.checked

	local function color()
		return if checked() then theme.acc(3)()
			else theme.bg(1)()
	end

	local function stroke()
		return if checked() then theme.acc(0)()
			else theme.bg(-3)()
	end

	return container {
		name = "Checkbox",
		
		w = 20, h = 20,
		flex = { justify = "center", align = "center" },

		color = color,
		stroke = stroke,
		thickness = theme.base_checkbox_thickness,
		corner = theme.base_button_corner,

		container {
			image = "rbxassetid://100188624502987",
			w = 16, h = 16, scale_type = Enum.ScaleType.Fit,
			transparency = spring(conditional(checked, 0, 1), 0.1)
		}
	}

end)