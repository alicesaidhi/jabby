local auto = require(script.Parent.Parent.util.auto)
local component = require(script.Parent.Parent.util.component)
local theme = require(script.Parent.Parent.util.theme)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)

local create = vide.create
local source = vide.source
local read = vide.read
local untrack = vide.untrack
local changed = vide.changed

type Can<T> = T | () -> T
return component(function(
	p: {
		-- frame properties
		color: Can<Color3>?,
		transparency: Can<number>?,

		-- stroke properties
		stroke: Can<Color3>?,
		thickness: Can<number>?,

		-- corner properties
		corner: Can<number>?,

		-- scroll container properties
		cw: Can<number>?,
		ch: Can<number>?,
		cws: Can<number>?,
		chs: Can<number>?,
		cx: Can<number>?,
		cy: Can<number>?,
		cauto: Can<"x" | "y" | "xy" | "">?,
	},
	_
)
	local current_cx = source(0)
	local current_cy = source(0)

	return create("ScrollingFrame" :: "ScrollingFrame") {
		BackgroundColor3 = p.color,
		BackgroundTransparency = p.transparency or if p.color then 0 else 1,

		CanvasPosition = if p.cx or p.cy
			then function()
				local cx, cy =
					p.cx or untrack(current_cx), p.cy or untrack(current_cy)
				return Vector2.new(read(cx :: number), read(cy :: number))
			end
			else nil,
		CanvasSize = if p.cws
				or p.cw
				or p.chs
				or p.ch
			then function()
				return UDim2.new(
					read(p.cws or 0),
					read(p.cw or 0),
					read(p.chs or 0),
					read(p.ch or 0)
				)
			end
			else UDim2.new(),
		AutomaticCanvasSize = if p.cauto
			then function() return auto(read(p.cauto)) end
			else nil,

		ScrollBarThickness = theme.base_scrollbar_thickness,
		ScrollBarImageColor3 = theme.bg_fg_low(3),

		if p.stroke
			then create("UIStroke" :: "UIStroke") {
				Color = p.stroke,
				Thickness = p.thickness or 1,
			}
			else nil,

		if p.corner
			then create("UICorner" :: "UICorner") {
				CornerRadius = function() return UDim.new(0, read(p.corner)) end,
			}
			else nil,

		changed("CanvasPosition", function(position: Vector2)
			current_cx(position.X)
			current_cy(position.Y)
		end),
	}
end)
