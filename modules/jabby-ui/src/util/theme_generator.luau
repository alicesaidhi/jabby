local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local oklab = require(script.Parent.oklab)

local derive = vide.derive
local read = vide.read

local LIGHT_THRESHOLD = 0.6
local STEP_SIZE_DEPTH = 0.02
local CONTRAST_LOW = 0.4
local CONTRAST_HIGH = 0.7

type Can<T> = T | () -> T

local function should_flip(light: number)
    return light > LIGHT_THRESHOLD
end

local function oklch_to_color3(oklch: vector)
    return oklab.linear_srgb_to_color3(
        oklab.oklab_to_linear_srgb(
            oklab.oklch_to_oklab(oklch)
        )
    )
end

--- @class Theme

--[=[
Computes a new color based on the given oklch value and contrast.
This is automatically optimized for either light or dark mode.
@within Theme
@param oklch vector
@param depth number
@param contrast number
@return vector
]=]
local function compute_color(
    oklch: vector,
    depth: number,
    contrast: number
): vector

    if should_flip(oklch.x) then
        oklch -= vector.create(contrast, 0, 0)
    else
        oklch += vector.create(contrast, 0, 0)
    end

    if should_flip(oklch.x) then
        oklch -= vector.create(depth * STEP_SIZE_DEPTH, 0, 0)
    else
        oklch += vector.create(depth * STEP_SIZE_DEPTH, 0, 0)
    end
    
    return oklch
end

local function obtain_color_generator(base: Can<vector>, depth: Can<number>, contrast: Can<number>)
    return function()
        return oklch_to_color3(compute_color(read(base), read(depth), read(contrast)))
    end
end

--[=[
Generates a lazily built sequence of colors based on a set of parameters.

@within Theme
@return { [number]: () -> Color3 }
]=]
local function compute_sequence(
    base: Can<vector>,
    contrast: Can<number>
)
    return function(depth: Can<number>)
        return obtain_color_generator(base, depth, contrast)
    end
end

return {

    compute_sequence = compute_sequence,
    generate_color = obtain_color_generator,
    compute_color = compute_color

}