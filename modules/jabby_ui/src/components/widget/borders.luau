local GuiService = game:GetService "GuiService"
local RunService = game:GetService "RunService"
local UserInputService = game:GetService "UserInputService"

local anim = require(script.Parent.Parent.Parent.util.anim)
local conditional = require(script.Parent.Parent.Parent.util.conditional)
local container = require(script.Parent.Parent.container)
local gradient = require(script.Parent.Parent.gradient)
local theme = require(script.Parent.Parent.Parent.util.theme)
local vide = require(script.Parent.Parent.Parent.Parent.roblox_packages.vide)

local source = vide.source
local changed = vide.changed
local cleanup = vide.cleanup

local THICKNESS = 4
local GRADIENT = NumberSequence.new {
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.25, 1),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(0.75, 1),
	NumberSequenceKeypoint.new(1, 1),
}

return function(p: {
	resize_range: number,

	can_resize_left: vide.Source<boolean>,
	can_resize_right: vide.Source<boolean>,
	can_resize_bottom: vide.Source<boolean>,
	can_resize_top: vide.Source<boolean>,
	resizing: () -> boolean,
})
	local RESIZE_RANGE = p.resize_range
	local can_resize_left = p.can_resize_left
	local can_resize_right = p.can_resize_right
	local can_resize_bottom = p.can_resize_bottom
	local can_resize_top = p.can_resize_top
	local resizing = p.resizing

	local absolute_size = source(Vector2.new(1, 1))
	local absolute_position = source(Vector2.zero)

	local border_selected = theme.acc(11)
	local x = source(0)
	local y = source(0)

	cleanup(RunService.Heartbeat:Connect(function()
		local mposition = UserInputService:GetMouseLocation()
		local top_inset, bottom_inset = GuiService:GetGuiInset()
		mposition += -top_inset - bottom_inset

		x(mposition.X)
		y(mposition.Y)
	end))

	cleanup(RunService.RenderStepped:Connect(function()
		local mposition = UserInputService:GetMouseLocation()
		local top_inset, bottom_inset = GuiService:GetGuiInset()
		mposition += -top_inset - bottom_inset
		local x, y = mposition.X, mposition.Y

		if resizing() then return end

		local left = absolute_position().X
		local top = absolute_position().Y
		local right = left + absolute_size().X
		local bottom = top + absolute_size().Y

		local topleft = absolute_position()
			- Vector2.new(RESIZE_RANGE, RESIZE_RANGE)
		local bottomright = absolute_position()
			+ absolute_size()
			+ Vector2.new(RESIZE_RANGE, RESIZE_RANGE)

		-- perform AABB to check if the cursor is in range
		local within_bounds = x > topleft.X
			and y > topleft.Y
			and x < bottomright.X
			and y < bottomright.Y

		can_resize_top(y > top - RESIZE_RANGE and y < top and within_bounds)
		can_resize_left(
			x < left + RESIZE_RANGE
				and x > left - RESIZE_RANGE
				and within_bounds
		)
		can_resize_bottom(
			y < bottom + RESIZE_RANGE
				and y > bottom - RESIZE_RANGE
				and within_bounds
		)
		can_resize_right(
			x < right + RESIZE_RANGE
				and x > right - RESIZE_RANGE
				and within_bounds
		)
	end))

	local mouse_x = function()
		return Vector2.new(
			(x() - absolute_position().X - absolute_size().X / 2)
				/ absolute_size().X,
			0
		)
	end
	local mouse_y = function()
		return Vector2.new(
			0,
			(y() - absolute_position().Y - absolute_size().Y / 2)
				/ absolute_size().Y
		)
	end

	return container {
		ws = 1,
		hs = 1,

		changed("AbsolutePosition", absolute_position),
		changed("AbsoluteSize", function(value: Vector2)
			if value.Magnitude == 0 then return end
			absolute_size(value)
		end),

		container {
			name = "left",

			xs = 0,
			ys = 0.5,
			w = THICKNESS,
			hr = THICKNESS * 2,
			anchor = { 1, 0.5 },

			color = border_selected,
			transparency = anim(conditional(can_resize_left, 0, 1)),

			gradient {
				rotation = 90,
				transparency = GRADIENT,
				offset = mouse_y,
			},
		},

		container {
			name = "right",

			xs = 1,
			ys = 0.5,
			w = THICKNESS,
			hr = THICKNESS * 2,
			anchor = { 0, 0.5 },

			color = border_selected,
			transparency = anim(conditional(can_resize_right, 0, 1)),

			gradient {
				rotation = 90,
				transparency = GRADIENT,
				offset = mouse_y,
			},
		},

		container {
			name = "top",

			xs = 0.5,
			ys = 0,
			h = THICKNESS,
			wr = THICKNESS * 2,
			anchor = { 0.5, 1 },

			color = border_selected,
			transparency = anim(conditional(can_resize_top, 0, 1)),

			gradient {
				rotation = 0,
				transparency = GRADIENT,
				offset = mouse_x,
			},
		},

		container {
			name = "bottom",

			xs = 0.5,
			ys = 1,
			h = THICKNESS,
			wr = THICKNESS * 2,
			anchor = { 0.5, 0 },

			color = border_selected,
			transparency = anim(conditional(can_resize_bottom, 0, 1)),

			gradient {
				rotation = 0,
				transparency = GRADIENT,
				offset = mouse_x,
			},
		},
	}
end
