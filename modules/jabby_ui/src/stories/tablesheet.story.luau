--!nonstrict
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local button = require(script.Parent.Parent.components.button)
local container = require(script.Parent.Parent.components.container)
local expandable = require(script.Parent.Parent.components.expandable)
local tablesheet = require(ReplicatedStorage.src.components.tablesheet)
local text = require(ReplicatedStorage.src.components.text)
local textfield = require(ReplicatedStorage.src.components.textfield)
local theme = require(script.Parent.Parent.util.theme)
local ui_labs = require(script.Parent.Parent.Parent.roblox_packages.ui_labs)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)

local source = vide.source
local effect = vide.effect

return ui_labs.CreateVideStory({
	vide = vide,
	controls = {
		enabled = true,
		compact = false,
		error = false,
		helper = "",
	},
}, function(props)
	local enabled = props.controls.enabled

	effect(function() theme.compact(props.controls.compact()) end)

	local oninput = source ""
	local onenter = source ""
	local onfocuslost = source ""

	return container {
		ws = 1,
		hs = 1,
		flex = { justify = "center", align = "center", pad = 8 },

		tablesheet {
			ws = 0.8,
			h = 300,

			enable_sort_key = true,
			auto_sort = true,

			columns = source {
				source { "id", 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 },
				source {
					"value",
					"a",
					"b",
					"c",
					"d",
					"e",
					"f",
					"g",
					"h",
					"i",
					"j",
					"k",
					"l",
					"m",
					"n",
				},
			},

			use_offset = source { 32 },

			field = function(value, column, row)
				return text {
					ws = 1,
					hs = 1,
					pad = { x = 8 },

					xalign = "left",

					text = function() return tostring(value()) end,
				}
			end,
		},
	}
end)
