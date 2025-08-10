local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local component = require(script.Parent.Parent.Parent.Parent.Parent.Parent.jabby_ui.src.util.component)
local jabby_ui = require(script.Parent.Parent.Parent.Parent.Parent.roblox_packages.jabby_ui)
local vide = require(script.Parent.Parent.Parent.Parent.Parent.roblox_packages.vide)

return component(function(p: {
	state: () -> "edited" | "removed" | "added" | "none",
	can_edit: boolean,
	editing: () -> boolean,
	value: () -> string,
	
	set_value: (string) -> (),
	lose_focus: (string) -> (),

	get_true_value: () -> string,
	edit_value: () -> (),
})
	return jabby_ui.container {
		ws = 1, auto = "y",
		
		vide.show(p.editing, function()
			local actual_value = vide.source(p.value())
			local editable = vide.source(false)
			local focused = vide.source(true)
			
			local enterpressed = vide.source(false)
			vide.cleanup(RunService.Heartbeat:Connect(function()
				enterpressed(UserInputService:IsKeyDown(Enum.KeyCode.LeftShift))
			end))

			task.spawn(function()
				actual_value(p.get_true_value())
				editable(true)
			end)

			return jabby_ui.container {
				name = "Component",
				ws = 1,
				clips = true, auto = "y",
				flex = { align = "center" },

				jabby_ui.textfield {
					ws = 1, auto = "y",
					size = 16, nocorner = true,
					multiline = enterpressed,

					monospace = p.can_edit,
					text = actual_value,
					editable = editable,
					focused = focused,

					focuslost = function(text: string, enter: boolean)
						if not enter then
							p.lose_focus(text)
						else
							p.set_value(text)
						end
					end
				},

				-- jabby_ui.context_menu {
				-- 	{
				-- 		kind = "action" :: "action", text = "Edit Component",
				-- 		clicked = function()
							
				-- 		end
				-- 	},
				-- 	{
				-- 		kind = "action" :: "action", text = "Track Component",
				-- 		clicked = function()
							
				-- 		end
				-- 	},							
				-- }
			}
		end, function()
			return jabby_ui.container {
				ws = 1,
				clips = true, auto = "y",
				flex = { align = "center" },
				pad = { x = 5, y = 3 },

				color = function(): Color3
					local state = p.state()
					return
						if state == "added" then jabby_ui.theme.suc(0)()
						elseif state == "edited" then jabby_ui.theme.wrn(0)()
						elseif state == "removed" then jabby_ui.theme.err(0)()
						else jabby_ui.theme.bg(0)()
				end,

				transparency = function()
					return if p.state() == "none" then 1 else 0.8
				end,

				jabby_ui.text {
					ws = 1, auto = "y",
					size = 16,

					xalign = "left",
					font = if p.can_edit then jabby_ui.theme.mono else nil,
					text = p.value
				},

				clicked = function()
					p.edit_value()
				end,

			}
		end)
	}
end)