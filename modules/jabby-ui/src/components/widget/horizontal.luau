local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage.roblox_packages.vide)
local container = require(ReplicatedStorage.src.components.container)
local state = require(script.Parent.state)
local component = require(ReplicatedStorage.src.util.component)
local theme = require(ReplicatedStorage.src.util.theme)

local create = vide.create
local source = vide.source
local changed = vide.changed

local TITLEBAR_SIZE = 32
local TABS_BAR = 24
local DRAGGER_SIZE = 8

return component(function(p: state.HorizontalWidget, children)

    local absolute_size = source(Vector2.zero)

    return container {
        name = "HorizontalWidget",
        wr = DRAGGER_SIZE,
        hs = 1,

        container {
            name = "Left",
            ws = p.position,
            w = -DRAGGER_SIZE / 2, hs = 1,

            
        },

        container {
            name = "Slider",

            w = 8, hs = 1,

            input = function(input)

            end
        },

        container {
            name = "Right",
            ws = function() return 1 - p.position() end,
            w = -DRAGGER_SIZE / 2, hs = 1,
            
        }
    }
end)