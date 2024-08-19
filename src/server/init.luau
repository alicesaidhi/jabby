local RunService = game:GetService("RunService")

local loop = require(script.Parent.modules.loop)

local step = loop(

	{i = 1}

)

RunService.Heartbeat:Connect(step)

return {}