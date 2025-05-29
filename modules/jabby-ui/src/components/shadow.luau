local component = require(script.Parent.Parent.util.component)
local container = require(script.Parent.container)


return component(function(_, _)
	return container {
		ws = 1, hs = 1,

		stroke = Color3.new(0, 0, 0),
		transparency = 0.8
	}
end)