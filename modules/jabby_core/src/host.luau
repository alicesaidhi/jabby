local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local jabby_types = require(script.Parent.Parent.roblox_packages.jabby_types)

return (if RunService:IsServer() then "server" else Players.LocalPlayer) :: jabby_types.Host