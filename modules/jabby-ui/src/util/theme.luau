
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local theme_generator = require(script.Parent.theme_generator)

local source = vide.source

local CONTRAST_LOW = 0.4
local CONTRAST_HIGH = 0.7

local background = source(vector.create(0.2012, 0.01, 0.6))
local accent = source(vector.create(0.52, 0.21, 0.71))

return {
    background = background,
    accent = accent,
    
    bg_fg_low = theme_generator.compute_sequence(background, CONTRAST_LOW),
    bg_fg_high = theme_generator.compute_sequence(background, CONTRAST_HIGH),
    acc_fg_low = theme_generator.compute_sequence(accent, CONTRAST_LOW),
    acc_fg_high = theme_generator.compute_sequence(accent, CONTRAST_HIGH),

    bg = theme_generator.compute_sequence(background, 0),
    acc = theme_generator.compute_sequence(accent, 0),
}