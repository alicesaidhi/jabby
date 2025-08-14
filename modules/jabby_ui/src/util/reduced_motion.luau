local GuiService = game:GetService "GuiService"
local RunService = game:GetService "RunService"

local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)

local source = vide.source

local reduced = source(GuiService.ReducedMotionEnabled)

RunService.Heartbeat:Connect(
	function() reduced(GuiService.ReducedMotionEnabled) end
)

return reduced
