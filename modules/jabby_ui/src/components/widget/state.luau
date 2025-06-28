local vide = require(script.Parent.Parent.Parent.Parent.roblox_packages.vide)
local map = require(script.Parent.Parent.Parent.util.map)

type Source<T> = vide.Source<T>

local effect = vide.effect
local derive = vide.derive
local source = vide.source
local cleanup = vide.cleanup
local untrack = vide.untrack
local batch = vide.batch
local root = vide.root

export type RootWidget = {
    kind: "root",
    children: Source<{ ChildWidget }>
}

export type RenderWidget = {
    kind: "render",
    parent: Source<TabsWidget?>,

    title: Source<string>,
    widget: Instance?,
    destroy: () -> (),

    min_w: number,
    min_h: number,
    w: number,
    h: number,
}

export type TabsWidget =  {
    kind: "tabs",
    parent: Source<ParentWidget?>,
    dragging: Source<Vector2?>,
    z: Source<number>,
    destroy: () -> (),

    x: Source<number>,
    y: Source<number>,
    
    w: Source<number>,
    h: Source<number>,

    min_w: () -> number,
    min_h: () -> number,

    tabs: Source<{ RenderWidget }>,
    selected: Source<number>,
}

export type HorizontalWidget = {
    kind: "horizontal",
    position: Source<number>,
    parent: Source<ParentWidget?>,
    dragging: Source<Vector2?>,
    z: Source<number>,
    destroy: () -> (),

    x: Source<number>,
    y: Source<number>,
    
    w: Source<number>,
    h: Source<number>,

    left: Source<ChildWidget>,
    right: Source<ChildWidget>,
    
    min_w: () -> number,
    min_h: () -> number,
}

export type VerticalWidget = {
    kind: "vertical",
    position: Source<number>,
    parent: Source<ParentWidget?>,
    dragging: Source<Vector2?>,
    z: Source<number>,
    destroy: () -> (),

    x: Source<number>,
    y: Source<number>,
    
    w: Source<number>,
    h: Source<number>,
    
    min_w: () -> number,
    min_h: () -> number,

    left: Source<ChildWidget>,
    right: Source<ChildWidget>,
}

export type ParentWidget = HorizontalWidget | VerticalWidget | RootWidget
export type ChildWidget = HorizontalWidget | TabsWidget | VerticalWidget

type Widget =
    | HorizontalWidget
    | VerticalWidget
    | TabsWidget
    | RootWidget

local ROOT: RootWidget = { kind = "root", children = source({}) }
local DRAGGER_SIZE = 6
local TABS_RIBBON_SIZE = 24
local TITLE_SIZE = 24

local function insert<T>(fn: () -> { T }, value: T)
    -- print("inserting", fn, value, debug.traceback("", 2))
    table.insert(untrack(fn), value)
end

local function find_pop<T>(fn: () -> { T }, value: T)
    local idx = table.find(fn(), value)
    -- print("try pop", fn, value)
    if not idx then return end
    -- print("popping", fn, value, debug.traceback("", 2))
    table.remove(untrack(fn), idx)
end

local function compute_min_w(self: Widget | RenderWidget): number
    return if self.kind == "render" then self.min_w
        elseif self.kind == "horizontal" then compute_min_w(self.left()) + compute_min_w(self.right()) + DRAGGER_SIZE
        elseif self.kind == "vertical" then math.max(0, compute_min_w(self.left()), compute_min_w(self.right()))
        elseif self.kind == "tabs" then math.max(0, unpack(map(self.tabs(), compute_min_w)))
        else 0
end

local function get_min_h_tab_additional(self: TabsWidget)
    local parent = self.parent()
    local addition = 0
    if parent and parent.kind ~= "root" then addition += TITLE_SIZE end
    if #self.tabs() > 1 then addition += TABS_RIBBON_SIZE end

    return addition
end

local function compute_min_h(self: Widget | RenderWidget): number
    return if self.kind == "render" then self.min_h
        elseif self.kind == "vertical" then compute_min_h(self.left()) + compute_min_h(self.right()) + DRAGGER_SIZE
        elseif self.kind == "horizontal" then math.max(0, compute_min_h(self.left()), compute_min_h(self.right()))
        elseif self.kind == "tabs" then math.max(0, unpack(map(self.tabs(), compute_min_h))) + get_min_h_tab_additional(self)
        else 0
end

local function noop() end

local function change_position(self: HorizontalWidget | VerticalWidget, to: number)
    local min
    local max

    if self.kind == "horizontal" then
        local min_left = self.left().min_w()
        local min_right = self.right().min_w()
        local w = self.w() - DRAGGER_SIZE

        min = min_left / w
        max = 1 - (min_right / w)
    else
        local min_left = self.left().min_h()
        local min_right = self.right().min_h()
        local h = self.h() - DRAGGER_SIZE

        min = min_left / h
        max = 1 - (min_right / h)
    end

    if min > max then max = min end
    local new = math.clamp(to, min, max)
    self.position(new)
end

--[[
    Removes the render widget from it's parent.
]]
local function remove_parent_render_widget(self: RenderWidget, from: TabsWidget)
    find_pop(from.tabs, self)
end

--[[
    Adds the render widget to a Tabs widget
]]
local function set_parent_render_widget(self: RenderWidget, to: TabsWidget)
    insert(to.tabs, self)
end

--[[
Obtains the size of a widget
]]
local function get_size(self: ChildWidget)
    local parent = self.parent()
    
    if not parent or parent.kind == "root" then
        return self.w(), self.h(), self.x(), self.y()
    elseif parent.kind == "horizontal" then
        local pos = parent.position()
        local w = parent.w() - DRAGGER_SIZE      

        if parent.left() == self then
            return w * pos, parent.h(), parent.x(), parent.y()
        else
            return w - w * pos, parent.h(), parent.x() + w * pos + DRAGGER_SIZE, parent.y()
        end
    elseif parent.kind == "vertical" then
        local pos = parent.position()
        local h = parent.h() - DRAGGER_SIZE

        if parent.left() == self then
            return parent.w(), h * pos, parent.x(), parent.y()
        else
            return parent.w(), h - h * pos, parent.x(), parent.y() + h * pos + DRAGGER_SIZE
        end
    end

    error("unreachable", parent)
end

--[[
Attempts to adjust the size so that everything will fit the widget again.
]]
local function fix_size(self: HorizontalWidget | VerticalWidget)
    -- get the left size and right size
    local lw, lh = get_size(self.left())
    local rw, rh = get_size(self.right())
    local lmw, lmh = self.left().min_w(), self.left().min_h()
    local rmw, rmh = self.right().min_w(), self.right().min_h()
    local parent = self.parent()
    
    if parent and parent.kind ~= "root" then fix_size(parent) end

    if self.kind == "horizontal" then
        if lmw > lw then
            self.left().w(lmw)
            self.w(lmw + rw + DRAGGER_SIZE)
            self.position(lmw / self.w())
            lw = lmw
        end
        if rmw > rw then
            self.right().w(lw)
            self.w(rmw + lw + DRAGGER_SIZE)
            self.position(rmw / self.w())
            lh = lmh
        end
        
        self.h(math.max(self.min_h(), self.h()))
        self.w(self.left().w() + self.right().w() + DRAGGER_SIZE)
    elseif self.kind == "vertical" then
        if lmh > lh then
            self.left().h(rmh)
            self.h(lmh + rh + DRAGGER_SIZE)
            self.position(lmh / self.h())
            lh = lmh
        end
        if rmh > rh then
            self.right().h(lh)
            self.h(rmh + lh + DRAGGER_SIZE)
            self.position(rmh / self.h())
        end

        self.w(math.max(self.min_w(), self.w()))
        self.h(self.left().h() + self.right().h() + DRAGGER_SIZE)
    end

    if parent and parent.kind ~= "root" then fix_size(parent) end
end

--[[
    Creates a new widget that will be rendered by a TabsWidget.
]]
local function widget(p: {
    title: Source<string>,
    min_w: number,
    min_h: number,

    w: number,
    h: number,

    fn: () -> Instance
}): RenderWidget
    local _, scope = root(function(destroy)
        local self: RenderWidget = {
            kind = "render",
            parent = source(nil :: TabsWidget?),
            
            title = p.title,
            widget = p.fn(),
            destroy = destroy,

            min_w = p.min_w,
            min_h = p.min_h,

            w = p.w,
            h = p.h
        }

        effect(function(old_parent: TabsWidget?)
            local new_parent = self.parent()
            if new_parent == old_parent then return new_parent end

            if old_parent then remove_parent_render_widget(self, old_parent) end
            if not new_parent then return new_parent end
            set_parent_render_widget(self, new_parent)
            return new_parent
        end)

        cleanup(function()
            self.destroy = noop
            self.widget = nil

            local parent = self.parent()
            if not parent then return end
            remove_parent_render_widget(self, parent)
        end)

        return self
    end)
    return scope :: any
end

--[[
Makes sure updating the size works properly
]]
local function update_size(self: ChildWidget)
    return function()
        local w, h, x, y = get_size(self)
        self.w(w)
        self.h(h)

        self.x(x)
        self.y(y)
    end
end

local function tabs(p: {
    x: number?,
    y: number?,

    [number]: RenderWidget
}): TabsWidget
    local _, scope = root(function(destroy)
        local tabs = source({} :: { RenderWidget })
        local self: TabsWidget = {
            kind = "tabs",
            parent = source(nil :: ParentWidget?),
            destroy = destroy,
            z = source(0),
            dragging = source(nil :: Vector2?),
            
            x = source(p.x or 100),
            y = source(p.y or 100),
            
            w = function() return 0 end,
            h = function() return 0 end,

            min_w = function() return 0 end,
            min_h = function() return 0 end,

            tabs = tabs,
            selected = source(1),

            _tabs = tabs()
        }

        effect(function()
            self._parent = tostring(self.parent())
        end)

        cleanup(function()
            self.destroy = noop
            for _, tab in tabs() do
                tab.destroy()
            end
        end)

        for _, tab in { unpack(p) } do
            tab.parent(self)
        end

        self.w = source(math.max(0, unpack(map(tabs(), function(v: RenderWidget) return v.w end))))
        self.h = source(math.max(0, unpack(map(tabs(), function(v: RenderWidget) return v.h end))))

        effect(function()
            if #tabs() ~= 0 then return end
            task.defer(self.destroy)
            self.destroy = noop
        end)

        self.min_w = derive(function()
            return compute_min_w(self)
        end)
        self.min_h = derive(function()
            return compute_min_h(self)
        end)

        effect(update_size(self))

        return self
    end)

    return scope
end

-- local NON_EXISTENT_TAB: TabsWidget = {
--     kind = "tabs",
--     parent = noop :: any,
--     destroy = noop :: any,
--     z = function() return 0 end :: any,
--     dragging = function() return false end :: any,

--     x = function() return 0 end,
--     y = function() return 0 end,
    
--     w = function() return 0 end :: any,
--     h = function() return 0 end :: any,

--     min_w = function() return 0 end :: any,
--     min_h = function() return 0 end :: any,

--     tabs = function() return {} end :: any,
--     selected = function() return 1 end :: any
-- }

local function horizontal(p: {
    x: number?,
    y: number?,
    position: number?,

    [number]: ChildWidget
}): HorizontalWidget

    local _, self = root(function(destroy)
        local self: HorizontalWidget = {
            kind = "horizontal" :: "horizontal",
            position = source(if p[1] == nil or p[2] == nil then p.position or 0.5 else p[1].w() / (p[1].w() + p[2].w())),
            parent = source(nil :: ParentWidget?),
            destroy = destroy,
            z = source(0),
            dragging = source(nil :: Vector2?),
            
            x = source(p.x or 100),
            y = source(p.y or 100),

            w = source(p[1].w() + p[2].w() + DRAGGER_SIZE),
            h = source(math.max(p[1].h(), p[2].h())),

            min_w = function() return 0 end,
            min_h = function() return 0 end,

            left = source(p[1]),
            right = source(p[2]),

            _left = p[1],
            _right = p[2]
        }

        effect(function()
            self._left = self.left()
            self._right = self.right()
            self._parent = tostring(self.parent())
        end)

        self.left().parent(self)
        self.right().parent(self)

        effect(update_size(self))

        cleanup(function()
            self.destroy = noop

            if self.left().parent() == self then
                self.left().destroy()
            end
            if self.right().parent() == self then
                self.right().destroy()
            end
        end)

        p[1].parent(self)
        p[2].parent(self)

        self.min_w = derive(function()
            return compute_min_w(self)
        end)
        self.min_h = derive(function()
            return compute_min_h(self)
        end)

        return self
    end)

    return self
end

local function vertical(p: {
    x: number?,
    y: number?,
    position: number?,

    [number]: ChildWidget
}): VerticalWidget

    local _, self = root(function(destroy)
        local self: VerticalWidget = {
            kind = "vertical" :: "vertical",
            position = source(p.position or p[1].h() / (p[1].h() + p[2].h())),
            parent = source(nil :: ParentWidget?),
            destroy = destroy,
            z = source(0),
            dragging = source(nil :: Vector2?),
            
            x = source(p.x or 100),
            y = source(p.y or 100),
            
            w = source(math.max(p[1].w(), p[2].w())),
            h = source(p[1].h() + p[2].h() + DRAGGER_SIZE),

            min_w = function() return 0 end,
            min_h = function() return 0 end,

            left = source(p[1]),
            right = source(p[2])
        }

        effect(function()
            self._left = self.left()
            self._right = self.right()
            self._parent = tostring(self.parent())
        end)

        effect(update_size(self))

        cleanup(function()
            self.destroy = noop

            if self.left().parent() == self then
                self.left().destroy()
            end
            if self.right().parent() == self then
                self.right().destroy()
            end
        end)

        p[1].parent(self)
        p[2].parent(self)

        self.min_w = derive(function()
            return compute_min_w(self)
        end)
        self.min_h = derive(function()
            return compute_min_h(self)
        end)

        return self
    end)

    return self
end

local function root(p: {
    [number]: ChildWidget
})
    for _, child in p do
        insert(ROOT.children, child)
        child.parent(ROOT)
    end
    ROOT.children(ROOT.children())
end

--[[
    Replaces the given widget with a different ChildWidget.
]]
local function replace_itself(self: ChildWidget, replacement: ChildWidget)
    local parent = self.parent()

    if parent and (parent.kind == "horizontal" or parent.kind == "vertical") then
        if parent.left() == self then
            parent.left(replacement)
            replacement.parent(parent)
        elseif parent.right() == self then
            parent.right(replacement)
            replacement.parent(parent)
        else
            error("parent is not part of ancestor")
        end
    elseif parent then
        insert(parent and parent.children, replacement)
        if self then
            find_pop(parent and parent.children, self)
            self.parent(parent)
            parent.children(parent.children())
        end
        replacement.w(self.w())
        replacement.h(self.h())
        replacement.x(self.x())
        replacement.y(self.y())
        replacement.parent(parent or ROOT)
    end
end

--[[
    Given a widget, takes the parent widget, grabs the other widget that isn't itself,
    then sets that to the parent of the parent widget on the same side as the parent widget,
    replacing the parent widget and destroys the parent widget.
]]
local function swap_parent_ancestor(self: ChildWidget)
    local parent = self.parent()
    -- since the widget is parented to root, there is no widget to swap.
    if not parent then return end
    if parent.kind == "root" then
        find_pop(parent.children, self)
        parent.children(parent.children())
        return
    end

    local other_widget

    -- obtains the other widget
    if parent.left() == self then
        other_widget = parent.right()
    else
        other_widget = parent.left()
    end

    -- the ancestor is root, so the other widget also goes into root
    replace_itself(parent, other_widget)
end

--[[
    Given a tab widget, if the widget has 0 tabs, swap parent ancestor and
    destroy the tab widget.
]]
local function if_no_tab_swap(self: TabsWidget)
    if #self.tabs() == 0 then
        swap_parent_ancestor(self)
        self.destroy()
    end
end

--[[
    Used for the dragging out action, which removes a tab from it's parent, giving
    it it's own widget that can be used anywhere.
]]
local function drag_out_tab(tab: RenderWidget, dragging: Vector2?): TabsWidget
    local p = tab.parent()
    local x, y = 64, 64
    if p then
        tab.w = p.w()
        tab.h = p.h()
        x = p.x()
        y = p.y()

        -- we have to remove the old parent
        remove_parent_render_widget(tab, p)
        p.tabs(p.tabs())
        if_no_tab_swap(p)
    end

    local child = tabs {
        x = x, y = y,
        tab
    }

    insert(ROOT.children, child)
    child.parent(ROOT)
    ROOT.children(ROOT.children())
    child.dragging(dragging)

    return child
end

--[[
    Closes the given render widget
]]
local function close_tab_widget(tab: Widget | RenderWidget)
    if tab.kind == "root" then return end
    if tab.kind == "render" then
        local parent = tab.parent()
        tab.parent(nil)
        if parent then if_no_tab_swap(parent) end
        tab.destroy()
    else
        swap_parent_ancestor(tab)
        tab.destroy()
    end
end

local function get_render_widgets(widget: ChildWidget | ParentWidget, add_to: { RenderWidget }?): { RenderWidget }
    local insert_into: { RenderWidget } = add_to or {}
    
    if widget.kind == "horizontal" then
        get_render_widgets(widget.left(), insert_into)
        get_render_widgets(widget.right(), insert_into)
    elseif widget.kind == "vertical" then
        get_render_widgets(widget.left(), insert_into)
        get_render_widgets(widget.right(), insert_into)
    elseif widget.kind == "root" then
        for _, widget in widget.children() do
            get_render_widgets(widget, add_to)
        end
    elseif widget.kind == "tabs" then
        table.move(widget.tabs(), 1, #widget.tabs(), #insert_into + 1, insert_into)
    end

    return insert_into
end

type Direction = "left" | "right" | "top" | "bottom" | "center"

--[[
    Used for docking into another widget
]]
local function dock_into_widget(docking: ChildWidget, docks_into: ChildWidget, direction: Direction)
    local old_parent = docks_into.parent()
    if not old_parent then return end
    if direction == "left" then
        swap_parent_ancestor(docking)
        -- we have to replace docks_into with our own widget
        local new_widget = horizontal {
			x = docks_into.x() - docking.w() - DRAGGER_SIZE, y = docks_into.y(),
            position = 0.5,
            docking, docks_into
        }
        docks_into.parent(old_parent)
        replace_itself(docks_into, new_widget)
        docks_into.parent(new_widget)

        fix_size(new_widget)
    elseif direction == "right" then
        swap_parent_ancestor(docking)
        -- we have to replace docks_into with our own widget
        local new_widget = horizontal {
            x = docks_into.x(), y = docks_into.y(),
            position = 0.5,
            docks_into, docking,
        }
        
        docks_into.parent(old_parent)
        replace_itself(docks_into, new_widget)
        docks_into.parent(new_widget)
        fix_size(new_widget)
	elseif direction == "top" then
        swap_parent_ancestor(docking)
        local new_widget = vertical {
            x = docks_into.x(), y = docks_into.y() - docking.h() - DRAGGER_SIZE,
            position = 0.5,
            docking,
            docks_into,
        }
        
        docks_into.parent(old_parent)
        replace_itself(docks_into, new_widget)
        docks_into.parent(new_widget)
        fix_size(new_widget)
    elseif direction == "bottom" then
        swap_parent_ancestor(docking)
        local new_widget = vertical {
            x = docks_into.x(), y = docks_into.y(),
            position = 0.5,
            docks_into,
            docking,
        }
        
        docks_into.parent(old_parent)
        replace_itself(docks_into, new_widget)
        docks_into.parent(new_widget)
        fix_size(new_widget)
    elseif direction == "center" then
        swap_parent_ancestor(docking)
        local render_widgets = get_render_widgets(docking)
        get_render_widgets(docks_into, render_widgets)
        
        for _, widget in render_widgets do
            local parent = widget.parent()
            assert(parent, "widget is a child, but not parented? should not happen")
        end

        local new_widget = tabs {
            x = docks_into.x(), y = docks_into.y(),
            unpack(render_widgets)
        }
        
        docks_into.parent(old_parent)
        replace_itself(docks_into, new_widget)
        docks_into.destroy()
    end

end

local enable_ui = source(true)

return {
    enable_ui = enable_ui,
    noop = noop,
    dragging = source(false),
    hovering_over = source(false :: false | {
        direction: Direction, 
        widget: TabsWidget
    }),

    ROOT = ROOT,
    TITLE_SIZE = TITLE_SIZE,
    DRAGGER_SIZE = DRAGGER_SIZE,
    RIBBON_SIZE = TABS_RIBBON_SIZE,

    root = root,
    tabs = tabs,
    widget = widget,
    horizontal = horizontal,
    vertical = vertical,

    close_tab = close_tab_widget,
    dock_into_widget = dock_into_widget,
    drag_out_tab = drag_out_tab,
    change_position = change_position,
}
