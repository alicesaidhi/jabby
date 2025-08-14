--!nonstrict
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local button = require(script.Parent.Parent.components.button)
local container = require(script.Parent.Parent.components.container)
local expandable = require(script.Parent.Parent.components.expandable)
local text = require(ReplicatedStorage.src.components.text)
local textfield = require(ReplicatedStorage.src.components.textfield)
local theme = require(script.Parent.Parent.util.theme)
local ui_labs = require(script.Parent.Parent.Parent.roblox_packages.ui_labs)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local virtualscroller =
	require(ReplicatedStorage.src.components.virtualscroller)

local source = vide.source
local effect = vide.effect

return ui_labs.CreateVideStory({
	vide = vide,
	controls = {},
}, function(props)
	return virtualscroller {
		ws = 1,
		hs = 1,
		item = function(index)
			return container {
				ws = 1,
				hs = 1,

				text {
					text = function() return `Item: {index()}` end,
				},
			}
		end,

		item_size = 32,

		max_items = vide.source(1500),
	}
end)
