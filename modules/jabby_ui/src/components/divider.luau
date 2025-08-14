local container = require(script.Parent.container)
local theme = require(script.Parent.Parent.util.theme)

return function()
	return container {
		h = 1,
		w = 1,
		grow = 1,
		shrink = 1,

		color = theme.bg_fg_low(0),
	}
end
