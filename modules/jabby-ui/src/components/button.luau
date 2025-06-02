local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local component = require(script.Parent.Parent.util.component)
local theme = require(script.Parent.Parent.util.theme)
local container = require(script.Parent.container)
local text = require(script.Parent.text)

local source = vide.source
local spring = vide.spring

type Can<T> = T | () -> T
return component(function(p: {
	corner: number?,
	padding: number?,
	paddingx: number?,

	acc: boolean?,

	text: Can<string>?,
    size: Can<number>?,
    font: Can<Font>?,
    truncate: "split" | "end"?,

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

		flex = { direction = "row", justify = "between", align = "center", pad = 8 },
		auto = "xy", pad = { x = p.paddingx, p = p.padding or theme.base_button_padding },
		corner = p.corner or theme.base_button_corner,

		color = spring(if p.acc then theme.acc(depth_acc) else theme.bg(depth_bg), 0.1),
		stroke = if p.acc then theme.acc(-7) else theme.bg(-1),
		thickness = theme.base_button_thickness,

		hover = hover, --FIXME: luau bug
		hold = hold,
		sink = enabled,
		enabled = enabled,
		clicked = p.clicked,

		if p.text then text {
			color = function()
				return if enabled and not enabled() then
					if p.acc then theme.acc_fg_low(3)()
					else theme.bg_fg_low(3)()
				else
					if p.acc then theme.acc_fg_high(depth_acc)()
					else theme.bg_fg_high(depth_bg)()
			end,

			text = p.text,
			size = p.size,
			font = p.font,
			truncate = p.truncate,
		} else nil
	}
end)