local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local component = require(script.Parent.Parent.util.component)
local guistate = require(script.Parent.Parent.util.guistate)

local create = vide.create
local read = vide.read

type Can<T> = T | () -> T

return component(function(p: {
	-- frame properties
	color: Can<Color3>?,
	transparency: Can<number>?,
	
	-- stroke properties
	stroke: Can<Color3>?,
	thickness: Can<number>?,

	-- corner properties
	corner: Can<number>?,

	-- image properties
	image: Can<Content | string>?,
	scale_type: Can<Enum.ScaleType>?,
	rect_offset: Can<Vector2>?,
	rect_size: Can<Vector2>?,
	pixelated: Can<boolean>?,
	slice_center: Can<Rect>?,
	slice_scale: Can<number>?,
	tile_size: Can<UDim2>?,

	-- input properties
    sink: Can<boolean>?,
	enabled: (() -> boolean)?,
	hover: ((boolean) -> ())?,
	hold: ((boolean) -> ())?,
	input: ((InputObject) -> ())?,
	clicked: ((InputObject) -> ())?,
}, _)
	
	local properties: any = {}

	if p.image then
		properties = {
			Image = p.image,
			ImageColor3 = p.color,
			ImageTransparency = p.transparency or if p.color then 0 else 1,
			ScaleType = p.scale_type or Enum.ScaleType.Stretch,
			ImageRectOffset = p.rect_offset,
			ImageRectSize = p.rect_size,
			SliceCenter = p.slice_center,
			SliceScale = p.slice_scale,
			TileSize = p.tile_size,
			BackgroundTransparency = 1
		}
	else
		properties = {
            BackgroundColor3 = p.color,
            BackgroundTransparency = p.transparency or if p.color then 0 else 1
        }
	end

	if p.sink ~= nil then
		properties.Active = p.sink
	end

	if not (p.ws or p.hs) then
		properties.AnchorPoint = Vector2.new(0.5, 0.5)
	end

	local interactable = p.clicked or p.hold or p.hover

	if interactable then
		table.insert(properties, guistate(p))
	end

	if p.stroke then
		table.insert(properties, create ("UIStroke" :: "UIStroke") {
			Color = p.stroke,
			Thickness = p.thickness or 1
		})
	end

	if p.corner then
		table.insert(properties, create ("UICorner" :: "UICorner") {
			CornerRadius = function()
				return UDim.new(0, read(p.corner))
			end
		})
	end

	local element = if read(p.image) and interactable then "ImageButton"
		elseif read(p.image) and not interactable then "ImageLabel"
		elseif interactable then "ImageButton"
		else "Frame"

	return (create :: any)(element)(properties) :: Instance
end)