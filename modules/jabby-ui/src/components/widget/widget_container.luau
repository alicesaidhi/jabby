local UserInputService = game:GetService("UserInputService")

local vide = require(script.Parent.Parent.Parent.Parent.roblox_packages.vide)
local anim = require(script.Parent.Parent.Parent.util.anim)
local theme = require(script.Parent.Parent.Parent.util.theme)
local button = require(script.Parent.Parent.button)
local container = require(script.Parent.Parent.container)
local text = require(script.Parent.Parent.text)
local guide = require(script.Parent.guide)
local state = require(script.Parent.state)

local source = vide.source
local show = vide.show
local indexes = vide.indexes
local action = vide.action
local effect = vide.effect
local untrack = vide.untrack

local RIBBON_SIZE = state.RIBBON_SIZE
local DRAGGER_SIZE = state.DRAGGER_SIZE
local DRAG_UNTIL_POP = 32

local render, horizontal, vertical, tabs

function tabs(p: state.TabsWidget, layout: number)
	local stop = false

	return container {
		name = "Tabs",
		w = p.w, h = p.h,
		order = layout,
		anchor = { 0, 0 },
		grow = 1, shrink = 1,
		flex = {},
		clips = true,

		show(function()
			if state.dragging() == false then return false end

			local child: state.ParentWidget | state.ChildWidget = p
			while child and child.kind ~= "root" do
				if child.dragging() then return false end
				child = child.parent()
			end

			return true
		end, function()
			return guide(p)
		end),

		show(function()
			local parent = p.parent()
			return parent and parent.kind ~= "root"
		end, function()

			local hovering = source(false)

			return {
				container {
					name = "Border",
					z = 100,
					order = -3,

					ws = 1, h = 1,
					
					color = theme.bg(-1),
				},

				container {
					ws = 1, h = state.TITLE_SIZE - 2,
					flex = { direction = "row", gap = 8 },
					pad = { x = 8 },
					order = -2,

					color = theme.bg(3),

					text {
						text = function()
							local tabs = p.tabs()
							local widget = tabs[p.selected()]
							if widget == nil then return "" end
							return widget.title()
						end,
						
						size = theme.sub_size
					},

					input = function(input: InputObject)
						if input.UserInputState == Enum.UserInputState.End then stop = false; return end
						if stop then return end
						local pos = input.Position
						local drag = UserInputService:GetMouseLocation() - Vector2.new(pos.X, pos.Y)
						
						if drag.Magnitude > DRAG_UNTIL_POP then
							local tabs = p.tabs()
							local widget = tabs[p.selected()]
							if not widget then return end
							state.drag_out_tab(widget, Vector2.new(input.Position.X, input.Position.Y))
							stop = true
						end
					end,
					
					container { grow = 1, shrink = 1 },

					container {
						w = state.TITLE_SIZE - 6, h = state.TITLE_SIZE - 6,
						corner = 4,
						flex = {},

						color = anim(function()
							return if hovering() then theme.bg(6)()
								else theme.bg(3)()
						end),

						container {
							wr = -4, hr = -4,

							image = "rbxassetid://10747384394"
						},

						hover = hovering :: (boolean) -> (),
						clicked = function()
							local tabs = p.tabs()
							local widget = tabs[p.selected()]
							if not widget then return end
							state.close_tab(widget)
						end,
					}
				},

				container {
					name = "Border",
					z = 100, order = -1,

					ws = 1, h = 1,
					
					color = theme.bg(-1),

				},

			}
		end),

		container {
			name = "Render",
			ws = 1, hs = 1,
			grow = 1, shrink = 1, order = 0,

			action(function(self)
				effect(function(old: Instance?): Instance?
					local tabs = p.tabs()
					local widget = tabs[p.selected()]
					
					if old and old.Parent == self then
						old.Parent = nil
					end

					if widget == nil then return nil end
					if widget.widget == nil then return nil end
					widget.widget.Parent = self
					return widget.widget
				end)
			end)

		},

		show(function()
			return #p.tabs() > 1
		end, function()
			return container {
				name = "Tab Options", order = 1,
				ws = 1, h = RIBBON_SIZE,
				flex = { direction = "row", justify = "left" },
				pad = { x = 2 },
				color = theme.bg(-1),

				indexes(p.tabs, function(tab: () -> state.RenderWidget, idx: number)
					return button {
						w = 0, h = RIBBON_SIZE - 2,
						corner = 0,
						padding = 0, paddingx = 8,

						text = function()
							return tab().title()
						end,
						size = theme.sub_size,

						clicked = function()
							p.selected(idx)
						end,

						input = function(input: InputObject)
							if input.UserInputState == Enum.UserInputState.End then stop = false; return end
							if stop then return end
							local pos = input.Position
							local drag = UserInputService:GetMouseLocation() - Vector2.new(pos.X, pos.Y)
							
							if drag.Magnitude > DRAG_UNTIL_POP then
								local tabs = p.tabs()
								local widget = tabs[idx]
								if not widget then return end
								state.drag_out_tab(widget, Vector2.new(input.Position.X, input.Position.Y))
								p.tabs(p.tabs())
								stop = true
								p.selected(idx - 1)
							end
						end
					}

				end)
			}
		end)
	}
end

function horizontal(p: state.HorizontalWidget, layout: number)
	return container {
		name = "Horizontal",
		w = p.w, p.h,
		anchor = { 0, 0 },
		flex = { direction = "row", justify = "between", align = "fill" },
		grow = 1, shrink = 1,
		order = layout,

		render(p.left, -1),

		container {
			w = DRAGGER_SIZE, hs = 1,
			order = 0,
			color = theme.bg(3),

			input = function(input: InputObject)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
				local new = UserInputService:GetMouseLocation()
				
				local x = p.x()
				local size = p.w()

				state.change_position(p, (new.X - x) / size)
			end
		},
		
		render(p.right, 1)
	}
end

function vertical(p: state.VerticalWidget, layout: number)
	return container {
		name = "Vertical",
		w = p.w, p.h,
		order = layout,
		anchor = { 0, 0 },
		flex = { direction = "column", justify = "fill", vertical = "between" },
		grow = 1, shrink = 1,

		render(p.left, -1),

		container {
			ws = 1, h = DRAGGER_SIZE,
			color = theme.bg(3),

			input = function(input: InputObject)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
				local new = UserInputService:GetMouseLocation()
				
				local y = p.y()
				local size = p.h()

				state.change_position(p, (new.Y - y) / size)
			end
		},
		
		render(p.right, 1)
	}
end

--[[
Renders a horizontal or vertical widget
]]
function render(p: () -> state.ChildWidget, order: number): any
	return function()
		local p = p()
		
		return untrack(function()
			return if p.kind == "horizontal" then horizontal(p, order)
				elseif p.kind == "vertical" then vertical(p, order)
				else tabs(p, order)
		end)
	end
end

return render