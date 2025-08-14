local ecs_registry = require(script.Parent.widgets.ecs_registry)
local jabby_types =
	require(script.Parent.Parent.Parent.roblox_packages.jabby_types)
local jabby_ui = require(script.Parent.Parent.Parent.roblox_packages.jabby_ui)

return function(target: jabby_types.Target)
	return jabby_ui.widget.root {
		jabby_ui.widget.tabs {
			ecs_registry(target),
		},
	}
end
