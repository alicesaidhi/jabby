local Players = game:GetService("Players")

local queue = require(script.Parent.Parent.Parent.modules.queue)
local remotes = require(script.Parent.Parent.Parent.modules.remotes)
local reverse_connector = require(script.Parent.Parent.Parent.modules.reverse_connector)
local traffic_check = require(script.Parent.Parent.Parent.modules.traffic_check)


return function()

	local ping = queue(remotes.ping)

	for _, player in Players:GetPlayers() do
		if traffic_check.player_is_allowed(player) then
			remotes.new_server_registered:fire({
				namespace = "client",
				player = player
			})
		end
	end

	return function()
		for connector in ping:iter() do
			print("ping")
			local outgoing = reverse_connector(connector)
			remotes.new_server_registered:fire(outgoing)
		end
	end
end