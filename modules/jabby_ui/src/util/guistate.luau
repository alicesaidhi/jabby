local RunService = game:GetService "RunService"
local UserInputService = game:GetService "UserInputService"

local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)

local source = vide.source
local action = vide.action
local effect = vide.effect
local cleanup = vide.cleanup

type GuiState = {
	enabled: (() -> boolean)?,
	hover: ((boolean) -> ())?,
	hold: ((boolean) -> ())?,
	input: ((InputObject) -> ())?,
	clicked: ((InputObject) -> ())?,
	rightclick: ((InputObject) -> ())?,
}

return function(p: GuiState)
	local enabled = p.enabled or source(true)
	local input_object = source(nil :: InputObject?)

	effect(function()
		if enabled() == false then
			if p.hover then p.hover(false) end
			if p.hold then p.hold(false) end
		end
	end)

	local function input_ended(input: InputObject)
		if not enabled() or input ~= input_object() then return end
		input_object(nil)
		if p.hold then p.hold(false) end
		if p.input then p.input(input) end
		if
			p.rightclick
			and (input.UserInputType == Enum.UserInputType.MouseButton2)
		then
			p.rightclick(input)
		end
		if
			p.clicked
			and (
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			p.clicked(input)
		end
	end

	local function input_began(input: InputObject)
		if
			not enabled()
			or input.UserInputState ~= Enum.UserInputState.Begin
		then
			return
		end
		input_object(input)
		if p.hold then p.hold(true) end
		if p.input then p.input(input) end

		local connection: RBXScriptConnection
		connection = RunService.Heartbeat:Connect(function(dt)
			if p.input then p.input(input) end
			if input_object() ~= input then connection:Disconnect() end
		end)
	end

	local function input_changed(input: InputObject)
		if not enabled() or input ~= input_object() then return end
		assert(p.input)
		p.input(input)
	end

	local function defer_set<T>(fn: (T) -> (), value: T)
		return function() fn(value) end
	end

	return action(function(instance)
		assert(instance:IsA "GuiButton", "instance has no input events")

		cleanup(instance.InputBegan:Connect(input_began))
		cleanup(UserInputService.InputEnded:Connect(input_ended))
		effect(function() instance.Active = enabled() end)
		if p.input then
			cleanup(instance.InputChanged:Connect(input_changed))
		end

		if p.hover then
			cleanup(instance.MouseEnter:Connect(defer_set(p.hover, true)))
			cleanup(instance.MouseLeave:Connect(defer_set(p.hover, false)))
		end
	end)
end
