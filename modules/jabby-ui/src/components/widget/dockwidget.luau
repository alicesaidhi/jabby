local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local vide = require(script.Parent.Parent.Parent.Parent.roblox_packages.vide)
local anim = require(script.Parent.Parent.Parent.util.anim)
local theme = require(script.Parent.Parent.Parent.util.theme)
local container = require(script.Parent.Parent.container)
local cornered = require(script.Parent.Parent.cornered)
local ignore = require(script.Parent.Parent.ignore)
local shadow = require(script.Parent.Parent.shadow)
local text = require(script.Parent.Parent.text)
local borders = require(script.Parent.borders)
local state = require(script.Parent.state)
local widget_container = require(script.Parent.widget_container)

local source = vide.source
local cleanup = vide.cleanup

local TITLEBAR_SIZE = 32
local RESIZE_EXTENTS = 8

return function(p: state.VerticalWidget | state.TabsWidget | state.HorizontalWidget)
    assert(p.kind ~= "root")

    local can_resize_left = source(false)
    local can_resize_right = source(false)
    local can_resize_top = source(false)
    local can_resize_bottom = source(false)
    local resizing = source(false)

    local hovering = source(false)

    local top, left = GuiService:GetGuiInset()
    local old: Vector2? = Vector2.new(p.x() + 32, p.y() + top.Y + left.Y - TITLEBAR_SIZE + 8)
    cleanup(RunService.PreRender:Connect(function(dt)
        if not p.dragging() then return end
        if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            local hover = state.hovering_over()
            if hover then
                state.dock_into_widget(p, hover.widget, hover.direction)
                state.hovering_over(false :: false)
            end

            p.dragging(nil)
            state.dragging(false)
            return
        end
        state.dragging(true)
        local new = UserInputService:GetMouseLocation()
        assert(old)

        local relative = new - old

        p.x(relative.X + p.x())
        p.y(relative.Y + p.y())
        
        old = new
    end))
    
    return container {
        name = "Widget",
        x = p.x, y = function()
            return p.y() - TITLEBAR_SIZE
        end, anchor = { 0, 0 },
        w = p.w, h = function()
            return p.h() + TITLEBAR_SIZE
        end,
        flex = {},

        color = theme.bg(0),
        corner = 8,
        
        ignore {
            shadow { corner = 8 },
            
            borders {
                resize_range = RESIZE_EXTENTS,
                can_resize_left = can_resize_left,
                can_resize_right = can_resize_right,
                can_resize_top = can_resize_top,
                can_resize_bottom = can_resize_bottom,

                resizing = resizing
            },

            container {
                wr = RESIZE_EXTENTS * 2, hr = RESIZE_EXTENTS * 2,
                xs = 0.5, ys = 0.5,
                anchor = { 0.5, 0.5 },
                z = 10,
                
                enabled = function()
                    return can_resize_bottom() or can_resize_left() or can_resize_right() or can_resize_top()
                end,
                input = function(input: InputObject)
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    resizing(true)
                    local mposition = UserInputService:GetMouseLocation()
                    local top_inset, bottom_inset = GuiService:GetGuiInset()
                    mposition += -top_inset - bottom_inset
                    local x, y = mposition.X, mposition.Y

                    if can_resize_bottom() then p.h(math.max(y - p.y(), p.min_h())) end
                    if can_resize_right() then p.w(math.max(x - p.x(), p.min_w())) end
                    if can_resize_top() then
                        y += TITLEBAR_SIZE
                        p.h(math.max(p.y() + p.h() - y, p.min_h()))
                        p.y(math.min(y, p.y() + p.h() - p.min_h()))
                    end
                    if can_resize_left() then
                        p.w(math.max(p.x() + p.w() - x, p.min_w()))
                        p.x(math.min(x, p.x() + p.w() - p.min_w()))
                    end

                    if input.UserInputState == Enum.UserInputState.End then resizing(false) end
                end
            }
        },

        cornered {
            name = "Titlebar",
            z = 100,

            ws = 1, h = TITLEBAR_SIZE,
            topleft = 8, topright = 8,

            flex = { direction = "row", justify = "left", gap = 8 },
            pad = { x = 8 },

            color = theme.bg(3),

            text {
                text = function()
                    if p.kind == "tabs" then
                        local selected = p.selected()
                        local tabs = p.tabs()

                        return tabs[selected] and tabs[selected].title() or "Widget"
                    else
                        return "Widget"
                    end
                end,
                size = theme.header_size,
                weight = 600
            },

            input = function(input: InputObject)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                old = UserInputService:GetMouseLocation()
                p.dragging(Vector2.new(input.Position.X, input.Position.Y))
            end,

            container { grow = 1, shrink = 1 },

            container {
                w = TITLEBAR_SIZE - 6, h = TITLEBAR_SIZE - 6,
                flex = {},

                color = anim(function()
                    return if hovering() then theme.bg(6)()
                        else theme.bg(3)()
                end),

                container {
                    wr = -4, hr = -4,

                    image = "rbxassetid://10747384394"
                },

                corner = 4,

                hover = hovering :: (boolean) -> (),
                clicked = function()
                    state.close_tab(p)
                end,
            }
        },

        container {
            name = "Children",
            z = 50,
            
            ws = 1, h = p.h,

            widget_container(source(p), 0)
        }

    }

end