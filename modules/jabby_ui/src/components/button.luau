local component = require(script.Parent.Parent.util.component)
local container = require(script.Parent.container)
local pad = require(script.Parent.pad)
local text = require(script.Parent.text)
local theme = require(script.Parent.Parent.util.theme)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)

local source = vide.source
local spring = vide.spring
local read = vide.read

type Can<T> = T | () -> T
return component(function(
	p: {
		corner: number?,
		pad: pad.Pad?,
		stroke: boolean?,

		color_offset: Can<number>?,
		acc: boolean?,

		text: Can<string>?,
		size: Can<number>?,
		font: Can<Font>?,
		truncate: "split" | "end"?,

		enabled: (() -> boolean)?,
		input: ((InputObject) -> ())?,
		clicked: ((InputObject) -> ())?,
	},
	_
)
	local hover = source(false)
	local hold = source(false)
	local enabled = p.enabled

	local offset = p.color_offset or 0

	local function depth_bg()
		return if enabled and not enabled()
			then -2 + read(offset)
			elseif hold() then 1 + read(offset)
			elseif hover() then 4 + read(offset)
			else 2 + read(offset)
	end

	local function depth_acc()
		return if enabled and not enabled()
			then -5 + read(offset)
			elseif hold() then -8 + read(offset)
			elseif hover() then 3 + read(offset)
			else 0 + read(offset)
	end

	return container {
		name = "Button",

		hs = 0,
		auto = "xy",
		pad = p.pad or { p = theme.base_button_padding, y = 8 },
		corner = p.corner or theme.base_button_corner,

		color = spring(
			if p.acc then theme.acc(depth_acc) else theme.bg(depth_bg),
			0.1
		),
		stroke = if p.stroke ~= false
			then if p.acc
				then theme.acc(-7 + read(offset))
				else theme.bg(-1 + read(offset))
			else nil,
		thickness = theme.base_button_thickness,

		hover = hover, --FIXME: luau bug
		hold = hold,
		sink = enabled,
		enabled = enabled,
		clicked = p.clicked,
		input = p.input,

		if p.text
			then text {
				auto = "xy",
				xs = 0.5,
				ys = 0.5,
				anchor = { 0.5, 0.5 },
				color = function()
					return if enabled and not enabled()
						then if p.acc
							then theme.acc_fg_low(3 + read(offset))()
							else theme.bg_fg_low(3 + read(offset))()
						else if p.acc
							then theme.acc_fg_high(depth_acc)()
							else theme.bg_fg_high(depth_bg)()
				end,

				text = p.text,
				size = p.size,
				font = p.font,
				truncate = p.truncate,
			}
			else nil,
	}
end)
