local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local anim = require(script.Parent.Parent.util.anim)
local component = require(script.Parent.Parent.util.component)
local container = require(script.Parent.container)

local source = vide.source
local changed = vide.changed

return component(function(p: {
	expanded: () -> boolean
}, children)

	local size = source(Vector2.zero)
	local ysize = function()
		return if p.expanded() then size().Y else 0
	end

	return container {
		name = "expandable",

		ws = 1, hs = 0,
		h = anim(ysize, true),
		clips = true,

		container {
			name = "children",
			flex = { },
			
			ws = 1, auto = "y",

			changed("AbsoluteSize", size :: any),

			children :: any
		}
	}

end)