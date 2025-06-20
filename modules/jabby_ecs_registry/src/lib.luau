local jabby_types = require(script.Parent.Parent.roblox_packages.jabby_types)
local widget = require(script.Parent.components.widget)

return {

	open_client = function(target: jabby_types.Target)
		widget(target)
	end,

	net = require(script.Parent.net)

}