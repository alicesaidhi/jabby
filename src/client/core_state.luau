--[[

Stores some core state for the UI

]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local types = require(script.Parent.Parent.modules.types)
local videx = require(ReplicatedStorage.Packages.jorp.modules.videx)

return videx.new(
	{
		stored_servers = {} :: {types.ClientServerInfo}
	},
	function(self)
		return {

			register_server = function()

			end

		}
	end
)