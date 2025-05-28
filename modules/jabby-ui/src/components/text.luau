local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local component = require(script.Parent.Parent.util.component)
local guistate = require(script.Parent.Parent.util.guistate)
local theme = require(script.Parent.Parent.util.theme)

local create = vide.create
local read = vide.read

type Can<T> = T | () -> T

return component(function(p: {
	-- text properties
	color: Can<Color3>?,
	transparency: Can<number>?,
	
    text: Can<string>,
    size: Can<number>?,
    font: Can<Font>?,
    truncate: "split" | "end"?,

	-- stroke properties
	stroke: Can<Color3>?,
	thickness: Can<number>?,
}, _)
    return create ("TextLabel" :: "TextLabel") {
        AutomaticSize = Enum.AutomaticSize.None,
        
        BackgroundTransparency = 1,

        Text = p.text,
        TextColor3 = p.color or theme.bg_fg_high(0),
        TextTransparency = p.transparency,
        TextSize = p.size,
        TextTruncate = if p.truncate == "split" then Enum.TextTruncate.SplitWord
            elseif p.truncate == "end" then Enum.TextTruncate.AtEnd
            else Enum.TextTruncate.None,
        FontFace = p.font,

        if p.stroke then
            create ("UIStroke" :: "UIStroke") {
                Color = p.stroke,
                Thickness = p.thickness or 1
            }
        else nil
    }

end)