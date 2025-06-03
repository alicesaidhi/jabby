local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local jabby_core = require(script.Parent.Parent.Parent.roblox_packages.jabby_core)
local jabby_types = require(script.Parent.Parent.Parent.roblox_packages.jabby_types)
local net = require(script.Parent.Parent.net)

local registered_applets = jabby_core.active_applets

return function(applet: jabby_types.JabbyApplet<any>)

	net.get_registered_applets:connect(0):on_invoke(function(sender, _)
		print("received request")
		local socket, socket_id = net.add_registered_applet:open_socket(sender)

		local applets = {}

		for idx, applet in registered_applets do
			applets[idx] = {
				name = applet.name,
				description = applet.description,
				id = applet.unique_id,
				client = applet.client
			}
		end
		
		return {
			socket = socket_id,
			applets = applets
		}
	end)

	if RunService:IsClient() then
		jabby_core.open_client(applet, { id = 0, to = Players.LocalPlayer })
		jabby_core.open_client(applet, { id = 0, to = "server" })
	end

end