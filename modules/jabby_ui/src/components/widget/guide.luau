local GuiService = game:GetService "GuiService"
local RunService = game:GetService "RunService"
local UserInputService = game:GetService "UserInputService"

local anim = require(script.Parent.Parent.Parent.util.anim)
local conditional = require(script.Parent.Parent.Parent.util.conditional)
local container = require(script.Parent.Parent.container)
local portal = require(script.Parent.Parent.portal)
local state = require(script.Parent.state)
local theme = require(script.Parent.Parent.Parent.util.theme)
local vide = require(script.Parent.Parent.Parent.Parent.roblox_packages.vide)

local cleanup = vide.cleanup
local action = vide.action

return function(widget: state.TabsWidget)
	local function hover_object(
		direction: "top" | "left" | "right" | "center" | "bottom"
	)
		local current = state.hovering_over()
		if
			not current
			or current.widget.kind ~= "root" and widget.kind == "root"
			or current.widget.kind == "tabs"
				and widget.kind == "tabs"
				and current.widget.z() < widget.z()
		then
			state.hovering_over {
				direction = direction,
				widget = widget,
			}
		end
	end

	local function cancel_hover_object(
		direction: "top" | "left" | "right" | "center" | "bottom"
	)
		local hover = state.hovering_over()
		if not hover then return end
		if hover.direction == direction and hover.widget == widget then
			state.hovering_over(false :: false)
		end
	end

	--todo: make this clean
	local detect = function(
		direction: "bottom" | "center" | "left" | "right" | "top"
	)
		return action(function(object: Instance)
			assert(object:IsA "GuiBase2d", "no gui")

			cleanup(RunService.Heartbeat:Connect(function()
				local abs_pos = object.AbsolutePosition
				local abs_size = object.AbsoluteSize
				local top_inset, bottom_inset = GuiService:GetGuiInset()

				local pos = UserInputService:GetMouseLocation()
					- top_inset
					- bottom_inset
				if pos.X < abs_pos.X then
					return cancel_hover_object(direction)
				end
				if pos.Y < abs_pos.Y then
					return cancel_hover_object(direction)
				end
				if pos.X > abs_pos.X + abs_size.X then
					return cancel_hover_object(direction)
				end
				if pos.Y > abs_pos.Y + abs_size.Y then
					return cancel_hover_object(direction)
				end

				return hover_object(direction)
			end))
		end)
	end

	local is = function(
		direction: "bottom" | "center" | "left" | "right" | "top"
	)
		return function()
			local hover = state.hovering_over()
			return hover
				and hover.direction == direction
				and hover.widget == widget
		end
	end

	return portal {
		inherit_layout = true,
		display_order = 1e8,

		container {
			w = 150,
			h = 150,
			xs = 0.5,
			ys = 0.5,
			anchor = { 0.5, 0.5 },

			color = theme.bg_fg_low(0),
			transparency = 0.8,

			stroke = theme.bg(-1),

			container {
				w = 32,
				h = 32,
				xs = 0.5,
				ys = 0.5,
				x = 0,
				y = 0,
				anchor = { 0.5, 0.5 },

				stroke = theme.bg(-1),
				color = theme.acc(3),
				transparency = conditional(is "center", 0.5, 1),

				detect "center",
			},

			container {
				w = 32,
				h = 32,
				xs = 0.5,
				ys = 0.5,
				x = -48,
				y = 0,
				anchor = { 0.5, 0.5 },

				stroke = theme.bg(-1),
				color = theme.acc(3),
				transparency = conditional(is "left", 0.5, 1),

				detect "left",
			},

			container {
				w = 32,
				h = 32,
				xs = 0.5,
				ys = 0.5,
				x = 48,
				y = 0,
				anchor = { 0.5, 0.5 },

				stroke = theme.bg(-1),
				color = theme.acc(3),
				transparency = conditional(is "right", 0.5, 1),

				detect "right",
			},

			container {
				w = 32,
				h = 32,
				xs = 0.5,
				ys = 0.5,
				x = 0,
				y = 48,
				anchor = { 0.5, 0.5 },

				stroke = theme.bg(-1),
				color = theme.acc(3),
				transparency = conditional(is "bottom", 0.5, 1),

				detect "bottom",
			},

			container {
				w = 32,
				h = 32,
				xs = 0.5,
				ys = 0.5,
				x = 0,
				y = -48,
				anchor = { 0.5, 0.5 },

				stroke = theme.bg(-1),
				color = theme.acc(3),
				transparency = conditional(is "top", 0.5, 1),

				detect "top",
			},
		},
	}
end
