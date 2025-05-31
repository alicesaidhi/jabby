--[=[
NOTES FOR STYLING:

- strokes are theme.bg(-7)
- main background is theme.bg(0)
- foreground is theme.bg(1) and theme.bg(2)
- clickable elements are theme.bg(2), 4 when held, 1 when hold and -2 when disabled.
- elements that take in text are -2
- use low contrast for text on non clickable elements
- accent is foreground


]=]

local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local conditional = require(script.Parent.conditional)
local theme_generator = require(script.Parent.theme_generator)

local source = vide.source

local CONTRAST_LOW = 0.4
local CONTRAST_HIGH = 0.65

local background = source(vector.create(0.2512, 0.01, 0.6))
local accent = source(vector.create(0.405, 0.21, 0.71))
local error = source(vector.create(0.4, 0.11, 0.04))

local COMPACT = source(false)

return {
    background = background,
    accent = accent,
    compact = COMPACT,
    
    bg_fg_low = theme_generator.compute_sequence(background, CONTRAST_LOW),
    bg_fg_high = theme_generator.compute_sequence(background, CONTRAST_HIGH),
    acc_fg_low = theme_generator.compute_sequence(accent, CONTRAST_LOW),
    acc_fg_high = theme_generator.compute_sequence(accent, CONTRAST_HIGH),

    bg = theme_generator.compute_sequence(background, 0),
    acc = theme_generator.compute_sequence(accent, 0),
    err = theme_generator.compute_sequence(error, 0),

    body = source(Font.fromName("BuilderSans")),
    mono = source(Font.fromId(16658246179)),

    base_button_padding = conditional(COMPACT, 6, 9),
    base_button_corner = conditional(COMPACT, 5, 8),
    base_textfield_corner = conditional(COMPACT, 5, 8),
    base_table_corner = conditional(COMPACT, 8, 8),

    base_checkbox_thickness = conditional(COMPACT, 1, 1),
    base_button_thickness = conditional(COMPACT, 1, 2),
    base_textfield_thickness = conditional(COMPACT, 1, 2),
    base_scrollbar_thickness = conditional(COMPACT, 4, 6),

    table_element_size = conditional(COMPACT, 20, 28),

    sub_size = conditional(COMPACT, 12, 14),
    body_size = conditional(COMPACT, 16, 18),
    input_size = conditional(COMPACT, 16, 18),
    
    
}