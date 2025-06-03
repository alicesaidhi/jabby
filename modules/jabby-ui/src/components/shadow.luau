local component = require(script.Parent.Parent.util.component)
local container = require(script.Parent.container)


return component(function(p: { corner: number, }, _)
	return container {
		ws = 1, hs = 1,
		corner = p.corner,

		stroke = Color3.new(0, 0, 0),
		stroke_transparency = 0.8,
		thickness = 2,
	}
end)