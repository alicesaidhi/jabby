local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)

local create = vide.create
local read = vide.read

type Can<T> = T | () -> T
export type Gradient = {
	color: Can<ColorSequence>?,
	transparency: Can<NumberSequence>?,
	rotation: Can<number>?,
	offset: Can<Vector2>?,
}

return function(p: Gradient)
	return create("UIGradient" :: "UIGradient") {
		Color = p.color,
		Transparency = p.transparency,
		Rotation = p.rotation,
		Offset = p.offset,
	}
end
