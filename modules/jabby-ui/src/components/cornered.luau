local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage.roblox_packages.vide)
local container = require(script.Parent.container)
local component = require(ReplicatedStorage.src.util.component)

local read = vide.read

type Can<T> = T | () -> T

local function floor(value: Can<number>): Can<number>
    return if typeof(value) == "function" then function() return math.floor(value()) end
        else math.floor(value)
end

local corner = component(function(p: {
    size: Can<number>,
    anchor: { number },
    color: Can<Color3>?,
}, _)

    return container {
        w = p.size, h = p.size,
        clips = true,

        container {
            name = "corner",
            ws = 2, hs = 2,
            xs = -p.anchor[1], ys = -p.anchor[2],

            color = p.color,
            corner = p.size
        }
    }

end)

return component(function(p: {
    color: Can<Color3>?,

    topleft: Can<number>?,
    topright: Can<number>?,
    bottomleft: Can<number>?,
    bottomright: Can<number>?
}, children)

    local topleft = floor(p.topleft or 0)
    local topright = floor(p.topright or 0)
    local bottomleft = floor(p.bottomleft or 0)
    local bottomright = floor(p.bottomright or 0)

    return container {
        corner { name = "topleft", anchor = { 0, 0 }, xs = 0, ys = 0, size = topleft or 0, color = p.color },
        corner { name = "topright", anchor = { 1, 0 }, xs = 1, ys = 0, size = topright or 0, color = p.color },
        corner { name = "bottomleft", anchor = { 0, 1 }, xs = 0, ys = 1, size = bottomleft or 0, color = p.color },
        corner { name = "bottomright", anchor = { 1, 1 }, xs = 1, ys = 1, size = bottomright or 0, color = p.color },
        
        container {
            name = "left",
            ws = 0.5, w = 0,
            hr = function() return -read(topleft or 0) - read(bottomleft or 0) + 1 end,

            ys = 0.5, y = function() return read(topleft or 0) // 2 - read(bottomleft or 0) // 2 end,
            color = p.color,
            anchor = { 0, 0.5 },
        },

        container {
            name = "right",
            ws = 0.5, w = 0,
            hr = function() return -read(topright or 0) - read(bottomright or 0) + 1 + 1 end,

            xs = 1,
            ys = 0.5, y = function() return read(topright or 0) // 2 - read(bottomright or 0) // 2 end,
            color = p.color,
            anchor = { 1, 0.5 },
        },

        container {
            name = "top",
            hs = 0.5, h = 0,
            wr = function() return -read(topleft or 0) - read(topright or 0) + 1 end,

            xs = 0.5, x = function() return read(topleft or 0) // 2 - read(topright or 0) // 2 end,
            color = p.color,
            anchor = { 0.5, 0 },
        },

        container {
            name = "bottom",
            hs = 0.5, h = 0,
            wr = function() return -read(bottomleft or 0) - read(bottomright or 0) + 1 end,

            ys = 1,
            xs = 0.5, x = function() return read(bottomleft or 0) // 2 - read(bottomright or 0) // 2 end,
            color = p.color,
            anchor = { 0.5, 1 },
        },
        
        container {
            name = "Children",
            ws = 1, hs = 1,
            anchor = { 0, 0 },

            children
        }
    }

end)