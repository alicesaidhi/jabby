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
    widget: Instance,
    destroy: () -> (),

    min_w: number,
    min_h: number,
    w: number,
    h: number,
}

export type TabsWidget =  {
    kind: "tabs",
    parent: Source<ParentWidget>,
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

type ParentWidget = HorizontalWidget | VerticalWidget | RootWidget
type ChildWidget = HorizontalWidget | TabsWidget | VerticalWidget

type Widget =
    | HorizontalWidget
    | VerticalWidget
    | TabsWidget
    | RootWidget

local ROOT = { kind = "root", children = source({}) }
local DRAGGER_SIZE = 8
local TABS_RIBBON_SIZE = 24

local function compute_min_w(self: Widget | RenderWidget): number
    return if self.kind == "render" then self.min_w
        elseif self.kind == "horizontal" then compute_min_w(self.left()) + compute_min_w(self.right()) + DRAGGER_SIZE
        elseif self.kind == "vertical" then math.max(compute_min_w(self.left()), compute_min_w(self.right()))
        elseif self.kind == "tabs" then math.max(unpack(map(self.tabs(), compute_min_w)))
        else 0
end

local function compute_min_h(self: Widget | RenderWidget): number
    return if self.kind == "render" then self.min_h
        elseif self.kind == "vertical" then compute_min_h(self.left()) + compute_min_h(self.right()) + DRAGGER_SIZE
        elseif self.kind == "horizontal" then math.max(compute_min_h(self.left()), compute_min_h(self.right()))
        elseif self.kind == "tabs" then math.max(unpack(map(self.tabs(), compute_min_h))) + if #self.tabs() > 1 then TABS_RIBBON_SIZE else 0
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

--[=[
    Removes any references to the child from it's parent
]=]
local function remove_parent(self: ChildWidget, parent: ParentWidget)
    batch(function()
        if parent.kind == "root" then
            local children = parent.children()
            table.remove(children, table.find(children, self))
            parent.children(children)
        else
            local other_widget =
                if parent.left() == self then parent.right()
                else parent.left()

            local ancestor = parent.parent()
            other_widget.parent(ancestor)
            if ancestor.kind ~= "root" then
                if ancestor.left() == parent then
                    ancestor.left(other_widget)
                elseif ancestor.right() == parent then
                    ancestor.right(other_widget)
                end
                parent.destroy()
            else
                table.insert(ancestor.children(), ancestor)
                ancestor.children(ancestor.children())
            end
        end
    end)
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
    Sets the parent to root
]]
local function set_parent_to_root(self: ChildWidget, to: RootWidget)
    local children = untrack(to.children)
    table.insert(children, self)
    to.children(children)
end

--[[
Obtains the size of a widget
]]
local function get_size(self: ChildWidget): (number, number)
    local parent = self.parent()
    
    if parent.kind == "root" then
        return self.w(), self.h()
    elseif parent.kind == "horizontal" then
        local pos = parent.position()
        local w = parent.w() - DRAGGER_SIZE

        if parent.left() == self then
            return w * pos, parent.h()
        else
            return 1 - w * pos, parent.h()
        end
    elseif parent.kind == "vertical" then
        local pos = parent.position()
        local h = parent.h() - DRAGGER_SIZE

        if parent.left() == self then
            return parent.w(), h * pos
        else
            return parent.w(), 1 - h * pos
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
    return function(old_parent: ParentWidget?): ParentWidget
        local new_parent = self.parent()
        if old_parent == new_parent then return new_parent end
        if old_parent then
            remove_parent(self, old_parent)
        end
        
        if new_parent.kind == "root" then
            set_parent_to_root(self, new_parent)
        else
            assert(new_parent.left() == self or new_parent.right() == self, "updated parent, but left or right is not set to widget.")
        end

        return new_parent
    end
end

--[[
Makes sure updating the size works properly
]]
local function update_size(self: ChildWidget)
    return function()
        local w, h = get_size(self)
        self.w(w)
        self.h(h)
    end
end

local function tabs(p: {
    x: number,
    y: number,

    [number]: RenderWidget
}): TabsWidget
    local _, scope = root(function(destroy)
        local tabs = source({ unpack(p) } :: { RenderWidget })
        local self: TabsWidget
        self = {
            kind = "tabs",
            parent = source(ROOT :: ParentWidget),
            destroy = destroy,
            
            x = source(p.x),
            y = source(p.y),

            w = source(math.max(unpack(map(tabs(), function(v: RenderWidget) return v.w end)))),
            h = source(math.max(unpack(map(tabs(), function(v: RenderWidget) return v.h end)))),

            min_w = derive(function()
                return compute_min_w(self)
            end),
            min_h = derive(function()
                return compute_min_h(self) + if #tabs() > 1 then TABS_RIBBON_SIZE else 0
            end),

            tabs = tabs
        }

        effect(update_parent(self))
        effect(update_size(self))

        cleanup(function()
            self.destroy = noop
            for _, tab in tabs() do
                tab.destroy()
            end
            remove_parent(self, self.parent())
        end)

        for _, tab in tabs() do
            tab.parent(self)
        end
        
        effect(function()
            if #tabs() ~= 0 then return end
            destroy()
        end)

        return self
    end)

    return scope
end

local function horizontal(p: {
    x: number,
    y: number,

    [number]: ChildWidget
}): HorizontalWidget

    local _, self = root(function(destroy)
        local self: HorizontalWidget
        self = {
            kind = "horizontal" :: "horizontal",
            position = source(p[1].w() / (p[1].w() + p[2].w())),
            parent = source(ROOT :: ParentWidget),
            destroy = destroy,
            
            x = source(p.x),
            y = source(p.y),

            w = source(p[1].w() + p[2].w() + DRAGGER_SIZE),
            h = source(math.max(p[1].h(), p[2].h())),

            min_w = function()
                return compute_min_w(self)
            end,
            min_h = function()
                return compute_min_h(self)
            end,

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

        effect(function()
            fix_size(self)
        end)

        return self
    end)

    return self
end

local function vertical(p: {
    x: number,
    y: number,

    [number]: ChildWidget
}): VerticalWidget

    local _, self = root(function(destroy)
        local self: VerticalWidget
        self = {
            kind = "vertical" :: "vertical",
            position = source(p[1].h() / (p[1].h() + p[2].h())),
            parent = source(ROOT :: ParentWidget),
            destroy = destroy,
            
            x = source(p.x),
            y = source(p.y),

            
            w = source(math.max(p[1].w(), p[2].w())),
            h = source(p[1].h() + p[2].h() + DRAGGER_SIZE),

            min_w = function()
                return compute_min_w(self)
            end,
            min_h = function()
                return compute_min_h(self)
            end,

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

        effect(function()
            fix_size(self)
        end)

        return self
    end)

    return self
end

local function set_parent(self: ChildWidget, parent: ParentWidget | ChildWidget, dir: "left" | "right" | "top" | "bottom"?)
    if parent.kind == "root" then
        self.parent(parent)

        local children = parent.children()
        table.insert(children, self)
        parent.children(children)
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
        else
            table.insert(ancestor.children(), ancestor)
            ancestor.children(ancestor.children())
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
        else
            table.insert(ancestor.children(), ancestor)
            ancestor.children(ancestor.children())
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
        else
            table.insert(ancestor.children(), ancestor)
            ancestor.children(ancestor.children())
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
        else
            table.insert(ancestor.children(), ancestor)
            ancestor.children(ancestor.children())
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
        set_parent(child, ROOT)
    end
end

return {
    ROOT = ROOT,
    DRAGGER_SIZE = DRAGGER_SIZE,
    RIBBON_SIZE = TABS_RIBBON_SIZE,

    root = root,
    tabs = tabs,
    widget = widget,
    horizontal = horizontal,
    vertical = vertical,

    set_parent = set_parent,
    change_position = change_position,
}
