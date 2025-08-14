local component = require(script.Parent.Parent.util.component)
local container = require(script.Parent.container)
local theme = require(script.Parent.Parent.util.theme)

return component(
	function()
		return container {
			name = "Ribbon",
			ws = 1,
			h = 24,

			color = theme.bg(3),
		}
	end
)
