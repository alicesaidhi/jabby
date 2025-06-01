local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage.roblox_packages.vide)
local container = require(ReplicatedStorage.src.components.container)
local state = require(script.Parent.state)
local component = require(ReplicatedStorage.src.util.component)
local theme = require(ReplicatedStorage.src.util.theme)

local create = vide.create

local TITLEBAR_SIZE = 32
local TABS_BAR = 24
local DRAGGER_SIZE = 8

return component(function(p: state.VerticalWidget | state.TabsWidget | state.HorizontalWidget, children)

    return create ("ScreenGui" :: "ScreenGui") {
        name = "Widget",

        container {
            name = "Widget",
            auto = "xy",

            color = theme.bg(0),
            corner = 8,
            
            sink = true,

        }
    }

end)