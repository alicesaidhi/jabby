local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local component = require(script.Parent.Parent.util.component)
local theme = require(script.Parent.Parent.util.theme)
local container = require(script.Parent.container)

local source = vide.source
local spring = vide.spring

return component(function(p: {
	acc: boolean,

	enabled: (() -> boolean)?,
	clicked: ((InputObject) -> ())?
}, _)

	local hover = source(false)
	local hold = source(false)
	local enabled = p.enabled

	local function depth_bg()
		return
			if enabled and not enabled() then -2
			elseif hold() then 1
			elseif hover() then 4
			else 2
	end
	
	local function depth_acc()
		return
			if enabled and not enabled() then -5
			elseif hold() then -8
			elseif hover() then 3
			else 0
	end

	return container {
		name = "Button",
		w = 150, h = 40,
		corner = 8,

		color = spring(if p.acc then theme.acc(depth_acc) else theme.bg(depth_bg), 0.1),
		stroke = if p.acc then theme.acc(-7) else theme.bg(-3),

		hover = hover, --FIXME: luau bug
		hold = hold,
		enabled = enabled,
		clicked = p.clicked
	}
end)