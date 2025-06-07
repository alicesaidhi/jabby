local Players = game:GetService("Players")

local jabby_types = require(script.Parent.Parent.Parent.roblox_packages.jabby_types)
local jabby_ui = require(script.Parent.Parent.Parent.roblox_packages.jabby_ui)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local net = require(script.Parent.Parent.net)
local applets = require(script.Parent.applets)
local performance = require(script.Parent.performance)

return function()

	return jabby_ui.widget.root {
		jabby_ui.widget.horizontal {

			jabby_ui.widget.tabs {
				applets()
			},

			jabby_ui.widget.tabs {
				performance()
			},

		}
	}

end