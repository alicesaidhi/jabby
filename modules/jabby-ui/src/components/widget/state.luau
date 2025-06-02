local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage.roblox_packages.vide)
local map = require(ReplicatedStorage.src.util.map)

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
    parent: Source<ParentWidget>,
    dragging: Source<Vector2?>,
    z: Source<number>,
    destroy: () -> (),

    x: Source<number>,
    y: Source<number>,
    
    w: Source<number>,
    h: Source<number>,

    min_w: () -> number,
    min_h: () -> number,

    tabs: Source<{ RenderWidget }>
}

export type HorizontalWidget = {
    kind: "horizontal",
    position: Source<number>,
    parent: Source<ParentWidget>,
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
    parent: Source<ParentWidget>,
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

local NONE: RootWidget = { kind = "root", children = function() return {} end :: any }
local ROOT: RootWidget = { kind = "root", children = source({}) }
local DRAGGER_SIZE = 6
local TABS_RIBBON_SIZE = 24
local TITLE_SIZE = 24

local function compute_min_w(self: Widget | RenderWidget): number
    return if self.kind == "render" then self.min_w
        elseif self.kind == "horizontal" then compute_min_w(self.left()) + compute_min_w(self.right()) + DRAGGER_SIZE
        elseif self.kind == "vertical" then math.max(0, compute_min_w(self.left()), compute_min_w(self.right()))
        elseif self.kind == "tabs" then math.max(0, unpack(map(self.tabs(), compute_min_w)))
        else 0
end

local function compute_min_h(self: Widget | RenderWidget): number
    return if self.kind == "render" then self.min_h
        elseif self.kind == "vertical" then compute_min_h(self.left()) + compute_min_h(self.right()) + DRAGGER_SIZE
        elseif self.kind == "horizontal" then math.max(0, compute_min_h(self.left()), compute_min_h(self.right()))
        elseif self.kind == "tabs" then math.max(0, unpack(map(self.tabs(), compute_min_h))) + if self.parent().kind == "root" then 0 else TITLE_SIZE + if #self.tabs() > 1 then TABS_RIBBON_SIZE else 0 
        else 0
end

local function noop() end

local function fix_size(self: ParentWidget)
    batch(function()
        if self.kind == "horizontal" then
            local w_panels = self.w() - DRAGGER_SIZE
            local left_w = w_panels * self.position()
            local right_w = w_panels - left_w

            local min_w_left = self.left().min_w()
            local min_w_right = self.right().min_w()

            if min_w_left > left_w then
                self.w(right_w + min_w_left + DRAGGER_SIZE)
                self.position(min_w_left / (right_w + min_w_left))
            end

            if min_w_right > right_w then
                self.w(left_w + min_w_right + DRAGGER_SIZE)
                self.position(min_w_right / (left_w + min_w_right))
            end

            self.h(math.max(self.h(), self.left().min_h(), self.right().min_h()))
        elseif self.kind == "vertical" then
            local h_panels = self.h() - DRAGGER_SIZE
            local left_h = h_panels * self.position()
            local right_h = h_panels - left_h

            local min_h_left = self.left().min_h()
            local min_h_right = self.right().min_h()

            if min_h_left > left_h then
                self.h(right_h + min_h_left + DRAGGER_SIZE)
                self.position(min_h_left / (right_h + min_h_left))
            end

            if min_h_right > right_h then
                self.h(left_h + min_h_right + DRAGGER_SIZE)
                self.position(min_h_right / (left_h + min_h_right))
            end

            self.w(math.max(self.w(), self.left().min_w(), self.right().min_w()))
        end
    end)
end

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

    local new = math.clamp(to, min, max)
    self.position(new)
end

--[[
    Sets the parent to root
]]
local function set_parent_to_root(self: ChildWidget, to: RootWidget)
    local children = untrack(to.children)
    if table.find(children, self) then error("ALREADY IN ROOT") end
    table.insert(children, self)
    to.children(children)
end


--[=[
    Removes any references to the child from it's parent
]=]
local function remove_parent(self: ChildWidget, old_parent: ParentWidget)
    if self.kind == "root" then return end
    if old_parent.kind == "root" then
        local children = old_parent.children()
        local idx = table.find(children, self)
        if not idx then return end
        table.remove(children, idx)
        old_parent.children(children)
    elseif old_parent.destroy ~= noop then
        if old_parent.left() ~= self and old_parent.right() ~= self then return end

        local other_widget =
            if old_parent.left() == self then old_parent.right()
            else old_parent.left()

        local ancestor = old_parent.parent()
        if ancestor == self.parent() then return end

        print("moving widget to ancestor", self.kind, old_parent.kind, ancestor.kind)

        if ancestor.kind ~= "root" then
            if ancestor.left() == old_parent then
                ancestor.left(other_widget)
            elseif ancestor.right() == old_parent then
                ancestor.right(other_widget)
            else
                error("ancestor is not part of it?")
            end

            old_parent.parent(NONE)
            other_widget.parent(ancestor)
            old_parent.destroy()
        else
            old_parent.parent(NONE)
            other_widget.parent(ancestor)
            other_widget.w(old_parent.w())
            other_widget.h(old_parent.h())
            other_widget.x(old_parent.x())
            other_widget.y(old_parent.y())
            old_parent.destroy()
        end

    end
end

--[[
    Removes the render widget from it's parent.
]]
local function remove_parent_render_widget(self: RenderWidget, from: TabsWidget)
    local tabs = untrack(from.tabs)
    table.remove(tabs, table.find(tabs, self))
    from.tabs(tabs)
end

--[[
    Adds the render widget to a Tabs widget
]]
local function set_parent_render_widget(self: RenderWidget, to: TabsWidget)
    local tabs = untrack(to.tabs)
    table.insert(tabs, self)
    to.tabs(tabs)
end

--[[
Obtains the size of a widget
]]
local function get_size(self: ChildWidget)
    local parent = self.parent()
    
    if parent.kind == "root" then
        return self.w(), self.h(), self.x(), self.y()
    elseif parent.kind == "horizontal" then
        local pos = parent.position()
        local w = parent.w() - DRAGGER_SIZE

        if parent.left() == self then
            return w * pos, parent.h(), parent.x(), parent.y()
        else
            return w - w * pos, parent.h(), parent.x() + w * pos, parent.y()
        end
    elseif parent.kind == "vertical" then
        local pos = parent.position()
        local h = parent.h() - DRAGGER_SIZE

        if parent.left() == self then
            return parent.w(), h * pos, parent.x(), parent.y()
        else
            return parent.w(), h - h * pos, parent.x(), parent.y() + h * pos
        end
    end

    error("unreachable", parent)
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
Handles and makes sure that updating the parent works properly
]]
local function update_parent(self: ChildWidget)
    local prev_parent: ParentWidget?
    return function()
        local old_parent = prev_parent
        local new_parent = self.parent()
        prev_parent = new_parent

        if old_parent == new_parent then return end
        if old_parent then
            remove_parent(self, old_parent)
        end

        if new_parent.kind == "root" then
            set_parent_to_root(self, new_parent)
            print('added')
        else
            assert(new_parent.left() == self or new_parent.right() == self, "updated parent, but left or right is not set to widget.")
        end
    end
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
            parent = source(ROOT :: ParentWidget),
            destroy = destroy,
            z = source(0),
            dragging = source(nil :: InputObject?),
            
            x = source(p.x or 0),
            y = source(p.y or 0),
            
            w = function() return 0 end,
            h = function() return 0 end,

            min_w = function() return 0 end,
            min_h = function() return 0 end,

            tabs = tabs
        }

        cleanup(function()
            self.destroy = noop
            print("destroying tabs")
            for _, tab in tabs() do
                tab.destroy()
            end
            remove_parent(self, self.parent())
        end)

        for _, tab in { unpack(p) } do
            tab.parent(self)
        end

        self.w = source(math.max(unpack(map(tabs(), function(v: RenderWidget) return v.w end))))
        self.h = source(math.max(unpack(map(tabs(), function(v: RenderWidget) return v.h end))))

        effect(function()
            if #tabs() ~= 0 then return end
            print("destroying itself")
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
        effect(update_parent(self))

        return self
    end)

    return scope
end

local function horizontal(p: {
    x: number?,
    y: number?,

    [number]: ChildWidget
}): HorizontalWidget

    local _, self = root(function(destroy)
        local self: HorizontalWidget = {
            kind = "horizontal" :: "horizontal",
            position = source(p[1].w() / (p[1].w() + p[2].w())),
            parent = source(ROOT :: ParentWidget),
            destroy = destroy,
            z = source(0),
            dragging = source(nil :: InputObject?),
            
            x = source(p.x or 0),
            y = source(p.y or 0),

            w = source(p[1].w() + p[2].w() + DRAGGER_SIZE),
            h = source(math.max(p[1].h(), p[2].h())),

            min_w = function() return 0 end,
            min_h = function() return 0 end,

            left = source(p[1]),
            right = source(p[2])
        }

        effect(update_parent(self))
        effect(update_size(self))

        cleanup(function()
            self.destroy = noop

            if self.left().parent() == self then
                self.left().destroy()
            end
            if self.right().parent() == self then
                self.right().destroy()
            end

            remove_parent(self, self.parent())
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

    [number]: ChildWidget
}): VerticalWidget

    local _, self = root(function(destroy)
        local self: VerticalWidget = {
            kind = "vertical" :: "vertical",
            position = source(p[1].h() / (p[1].h() + p[2].h())),
            parent = source(ROOT :: ParentWidget),
            destroy = destroy,
            z = source(0),
            dragging = source(nil :: InputObject?),
            
            x = source(p.x or 0),
            y = source(p.y or 0),
            
            w = source(math.max(p[1].w(), p[2].w())),
            h = source(p[1].h() + p[2].h() + DRAGGER_SIZE),

            min_w = function() return 0 end,
            min_h = function() return 0 end,

            left = source(p[1]),
            right = source(p[2])
        }

        effect(update_parent(self))
        effect(update_size(self))

        cleanup(function()
            self.destroy = noop

            if self.left().parent() == self then
                self.left().destroy()
            end
            if self.right().parent() == self then
                self.right().destroy()
            end

            remove_parent(self, self.parent())
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

local function set_parent(self: ChildWidget, parent: ParentWidget | ChildWidget, dir: "left" | "right" | "top" | "bottom"?)
    if parent.kind == "root" then
        self.parent(parent)
    elseif dir == "left" then
        local other_widget = horizontal {
            x = 0, y = 0,

            self, parent
        }
        
        local ancestor = parent.parent()
        other_widget.parent(ancestor)
        if ancestor.kind ~= "root" then
            if ancestor.left() == parent then
                ancestor.left(other_widget)
            else
                ancestor.right(other_widget)
            end
        end

        fix_size(ancestor)
    elseif dir == "right" then
        local other_widget = horizontal {
            x = 0, y = 0,

            parent, self
        }
        
        local ancestor = parent.parent()
        other_widget.parent(ancestor)
        if ancestor.kind ~= "root" then
            if ancestor.left() == parent then
                ancestor.left(other_widget)
            else
                ancestor.right(other_widget)
            end
        end
        
        fix_size(ancestor)
    elseif dir == "top" then
        local other_widget = vertical {
            x = 0, y = 0,

            self,
            parent
        }
        
        local ancestor = parent.parent()
        other_widget.parent(ancestor)
        if ancestor.kind ~= "root" then
            if ancestor.left() == parent then
                ancestor.left(other_widget)
            else
                ancestor.right(other_widget)
            end
        end

        fix_size(ancestor)
    elseif dir == "bottom" then
        local other_widget = vertical {
            x = 0, y = 0,

            self,
            parent,
        }
        
        local ancestor = parent.parent()
        other_widget.parent(ancestor)
        if ancestor.kind ~= "root" then
            if ancestor.left() == parent then
                ancestor.left(other_widget)
            else
                ancestor.right(other_widget)
            end
        end
        
        fix_size(ancestor)
    elseif self.kind == "tabs" and parent.kind == "tabs" then
        for _, tab in self.tabs() do
            table.insert(parent.tabs(), tab)
        end

        parent.tabs(parent.tabs())
    else
        error("cannot parent")
    end
end

local function root(p: {
    [number]: ChildWidget
})
    for _, child in p do
        child.parent(ROOT)
    end
end

local function remove_tab(p: TabsWidget, tab: RenderWidget, dragging: Vector2?): TabsWidget
    tab.w = p.w()
    tab.h = p.h()

    local self = tabs {
        x = p.x(), y = p.y(),

        tab
    }
    self.dragging(dragging)

    return self
end

local enable_ui = source(true)

return {
    enable_ui = enable_ui,
    noop = noop,

    ROOT = ROOT,
    TITLE_SIZE = TITLE_SIZE,
    DRAGGER_SIZE = DRAGGER_SIZE,
    RIBBON_SIZE = TABS_RIBBON_SIZE,

    root = root,
    tabs = tabs,
    widget = widget,
    horizontal = horizontal,
    vertical = vertical,

    set_parent = set_parent,
    remove_tab = remove_tab,
    change_position = change_position,
}
