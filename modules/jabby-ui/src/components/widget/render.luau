local vide = require(script.Parent.Parent.Parent.Parent.roblox_packages.vide)
local dockwidget = require(script.Parent.dockwidget)
local state = require(script.Parent.state)

local create = vide.create
local values = vide.values

-- local TITLEBAR_SIZE = 32

return function()

	-- cleanup(UserInputService.InputEnded:Connect(function(input)
	-- 	-- if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	-- 	local x, y = input.Position.X, input.Position.Y
	-- 	local highest_order
	-- 	local highest_z = -math.huge

	-- 	--fixme: apparently roblox breaks if you change the zindex while an input is active 
	-- 	for _, root in state.ROOT.children() do
	-- 		if x < root.x() or y < root.y() - TITLEBAR_SIZE or x > root.x() + root.w() or y > root.y() - TITLEBAR_SIZE + root.y() then continue end
	-- 		if highest_z > root.z() then continue end
			
	-- 		highest_order = root
	-- 		highest_z = root.z()
	-- 	end

	-- 	if not highest_order then return end
	-- 	for _, root in state.ROOT.children() do
	-- 		if root == highest_order then continue end
	-- 		task.defer(function()
	-- 			root.z(root.z() - 1)
	-- 		end)
	-- 	end
	-- end))

	return values(function()
		if not state.enable_ui() then return {} :: any end
		return state.ROOT.children()
	end, function(child: state.ChildWidget, idx)
		assert(child.destroy ~= state.noop)

		return create ("ScreenGui" :: "ScreenGui") {
			Name = child.kind,
			DisplayOrder = child.z,

			dockwidget(child)
		}
	end)

end