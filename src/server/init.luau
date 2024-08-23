local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local loop = require(script.Parent.modules.loop)
local remotes = require(script.Parent.modules.remotes)
local traffic_check = require(script.Parent.modules.traffic_check)
local vm_id = require(script.Parent.modules.vm_id)
local scheduler = require(script.scheduler)

do
	for _, player in Players:GetPlayers() do
		if not traffic_check.player_is_allowed(player) then return end
		remotes.new_server_registered:fire({
			namespace = player,
		}) 
	end
end

local systems = script.systems
local loop = loop (
	`jorp-namespace:{
		if RunService:IsServer() then "server" else "client"
	}-vm:{vm_id}`,
	nil,
	{i = 1},

	systems.ping,
	systems.replicate_core
)

RunService.Heartbeat:Connect(loop)

return {}