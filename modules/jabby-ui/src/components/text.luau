local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local component = require(script.Parent.Parent.util.component)
local guistate = require(script.Parent.Parent.util.guistate)
local theme = require(script.Parent.Parent.util.theme)

local create = vide.create
local read = vide.read

type Can<T> = T | () -> T

local function find_weight(n: number): Enum.FontWeight
	for _, enum: EnumItem in Enum.FontWeight:GetEnumItems() do
		if math.abs(n - enum.Value) <= 50 then return enum :: any end
	end

	return Enum.FontWeight.Regular
end

return component(function(p: {
	-- text properties
	color: Can<Color3>?,
	transparency: Can<number>?,
    acc: boolean?,
	
    text: Can<string>,
    size: Can<number>?,
    font: Can<Font>?,
    wraps: Can<boolean>?,
    truncate: "split" | "end"?,
    
    xalign: "left" | "center" | "right"?,
    yalign: "top" | "center" | "bottom"?, 

    weight: Can<number>?,

	-- stroke properties
	stroke: Can<Color3>?,
	thickness: Can<number>?,
}, _)
    return create ("TextLabel" :: "TextLabel") {
        AutomaticSize = Enum.AutomaticSize.XY,
        AutoLocalize = false,

        BackgroundTransparency = 1,

        Text = p.text,
        TextColor3 = p.color or if p.acc then theme.acc_fg_high(0) else theme.bg_fg_high(0),
        TextTransparency = p.transparency,
        TextSize = p.size or theme.body_size,
        TextWrapped = p.wraps,
        TextTruncate = if p.truncate == "split" then Enum.TextTruncate.SplitWord
            elseif p.truncate == "end" then Enum.TextTruncate.AtEnd
            else Enum.TextTruncate.None,
            
        TextXAlignment =
            if p.xalign == "left" then Enum.TextXAlignment.Left
            elseif p.xalign == "center" then Enum.TextXAlignment.Center
            elseif p.xalign == "right" then Enum.TextXAlignment.Right
            else nil,
        TextYAlignment =
            if p.yalign == "top" then Enum.TextYAlignment.Top
            elseif p.yalign == "center" then Enum.TextYAlignment.Center
            elseif p.yalign == "bottom" then Enum.TextYAlignment.Bottom
            else nil,
            
		FontFace = function()
			local font = read(p.font or theme.body) :: Font
			return Font.new(font.Family, find_weight(read(p.weight or 400)), font.Style)
		end,

        if p.stroke then
            create ("UIStroke" :: "UIStroke") {
                Color = p.stroke,
                Thickness = p.thickness or 1
            }
        else nil
    }

end)