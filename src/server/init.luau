local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local loop = require(script.Parent.modules.loop)
local remotes = require(script.Parent.modules.remotes)
local traffic_check = require(script.Parent.modules.traffic_check)
local vm_id = require(script.Parent.modules.vm_id)
local public = require(script.public)
local scheduler = require(script.scheduler)

do
	for _, player in Players:GetPlayers() do
		if not traffic_check.player_is_allowed(player) then continue end
		remotes.new_server_registered:fire({
			host = player,
		}) 
	end
end

local systems = script.systems
local loop, jorp_scheduler = loop (
	`jorp-host:{
		if RunService:IsServer() then "server" else "client"
	}-vm:{vm_id}`,
	nil,
	{i = 1},

	systems.ping,
	systems.replicate_core,
	systems.replicate_scheduler,
	systems.replicate_registry,
	systems.mouse_pointer
)

table.insert(public, jorp_scheduler)

RunService.Heartbeat:Connect(loop)

return {}