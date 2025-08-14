local jabby_types =
	require(script.Parent.Parent.Parent.roblox_packages.jabby_types)
local jabby_ui = require(script.Parent.Parent.Parent.roblox_packages.jabby_ui)
local scheduler = require(script.Parent.widgets.scheduler)

return function(target: jabby_types.Target)
	return jabby_ui.widget.root {
		jabby_ui.widget.tabs {
			scheduler(target),
		},
	}
end
