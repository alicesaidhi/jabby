local applets = require(script.Parent.applets)
local jabby_ui = require(script.Parent.Parent.Parent.roblox_packages.jabby_ui)
local performance = require(script.Parent.performance)

return function()
	return jabby_ui.widget.root {
		jabby_ui.widget.horizontal {

			jabby_ui.widget.tabs {
				applets(),
			},

			jabby_ui.widget.tabs {
				performance(),
			},
		},
	}
end
