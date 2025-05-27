local ReplicatedStorage = game:GetService("ReplicatedStorage")

local oklab = require(script.Parent.oklab)
local vide = require(ReplicatedStorage.roblox_packages.vide)

local read = vide.read

local LIGHT_LIMIT = 0.6
local function should_flip(c: Color3)
    return oklab.linear_srgb_to_oklab(
        oklab.color3_to_linear_srgb(c)
    ).x > LIGHT_LIMIT
end

local function generate_color_sequence()

end