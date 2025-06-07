local Players = game:GetService("Players")

local jabby_types = require(script.Parent.Parent.Parent.roblox_packages.jabby_types)
local jabby_ui = require(script.Parent.Parent.Parent.roblox_packages.jabby_ui)
local net = require(script.Parent.Parent.net)
local widget = require(script.Parent.widget)

return {

	open_client = function()
		widget()
		jabby_ui.widget.mount_to(Players.LocalPlayer.PlayerGui)
	end

}