local UserInputService = game:GetService("UserInputService")

local vide = require(script.Parent.Parent.Parent.Parent.roblox_packages.vide)
local theme = require(script.Parent.Parent.Parent.util.theme)
local button = require(script.Parent.Parent.button)
local container = require(script.Parent.Parent.container)
local text = require(script.Parent.Parent.text)
local state = require(script.Parent.state)

local source = vide.source
local show = vide.show
local indexes = vide.indexes
local switch = vide.switch

local RIBBON_SIZE = state.RIBBON_SIZE
local DRAGGER_SIZE = state.DRAGGER_SIZE

local render, horizontal, vertical, tabs

function tabs(p: state.TabsWidget)
	local displaying_tab = source(1)
	local stop = false

	return container {
		name = "Tabs",
		w = p.w, h = p.h,
		anchor = { 0, 0 },
		flex = {},
		clips = true,

        container {
            name = "Border",
            z = 100,

            ws = 1, h = 1,
            
            color = theme.bg(-1),
        },

		show(function()
			return p.parent().kind ~= "root"
		end, function()
			return container {
				ws = 1, h = state.TITLE_SIZE - 2,
				flex = { direction = "row", gap = 8 },

				color = theme.bg(3),

				text {
					text = function()
						local tabs = p.tabs()
						local widget = tabs[displaying_tab()]
						if widget == nil then return "" end
						return widget.title()
					end,
					
					size = theme.sub_size
				},

				input = function(input: InputObject)
					if input.UserInputState == Enum.UserInputState.End then stop = true; return end
					if stop then return end
					local pos = input.Position
					local drag = UserInputService:GetMouseLocation() - Vector2.new(pos.X, pos.Y)
					
					if drag.Magnitude > 10 then
						local tabs = p.tabs()
						local widget = tabs[displaying_tab()]
						if not widget then return end
						state.remove_tab(p, widget, Vector2.new(input.Position.X, input.Position.Y))
						stop = true
					end
				end
			}
		end),

        container {
            name = "Border",
            z = 100,

            ws = 1, h = 1,
            
            color = theme.bg(-1),

        },

		container {
			name = "Render",
			ws = 1, hs = 1,
			grow = 1, shrink = 1,

			-- parents the widget
			function(): Instance?
				local tabs = p.tabs()
				local widget = tabs[displaying_tab()]
				if widget == nil then return nil end
				return widget.widget
			end
		},

		show(function()
			return #p.tabs() > 1
		end, function()
			return container {
				name = "Tab Options",
				ws = 1, h = RIBBON_SIZE,
				flex = { direction = "row", justify = "left" },
				pad = { x = 2 },

				color = theme.bg(-2),
			}
		end)
	}
end

function horizontal(p: state.HorizontalWidget)
	return container {
		name = "Horizontal",
		w = p.w, p.h,
		anchor = { 0, 0 },
		flex = { direction = "row" },

		render(p.left),

		container {
			w = DRAGGER_SIZE, hs = 1,
			color = theme.bg(3),

			input = function(input: InputObject)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
				local new = UserInputService:GetMouseLocation()
				
				local x = p.x()
				local size = p.w()

				state.change_position(p, (new.X - x) / size)
			end
		},
		
		render(p.right)
	}
end


function vertical(p: state.VerticalWidget)
	return container {
		name = "Vertical",
		w = p.w, p.h,
		anchor = { 0, 0 },
		flex = { direction = "column" },

		render(p.left),

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
		
		render(p.right)
	}
end

--[[
Renders a horizontal or vertical widget
]]
function render(p: () -> state.ChildWidget): any
	return switch(function()
		return p().kind
	end) {
		tabs = function()
			return tabs(p() :: state.TabsWidget)
		end,
		horizontal = function()
			return horizontal(p() :: state.HorizontalWidget)
		end,
		vertical = function()
			return vertical(p() :: state.VerticalWidget)
		end
	}
end

return render