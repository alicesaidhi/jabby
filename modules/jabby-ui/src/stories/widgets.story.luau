--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local text = require(ReplicatedStorage.src.components.text)
local textfield = require(ReplicatedStorage.src.components.textfield)
local virtualscroller = require(ReplicatedStorage.src.components.virtualscroller)
local ui_labs = require(script.Parent.Parent.Parent.roblox_packages.ui_labs)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local button = require(script.Parent.Parent.components.button)
local container = require(script.Parent.Parent.components.container)
local expandable = require(script.Parent.Parent.components.expandable)
local widget = require(script.Parent.Parent.components.widget)
local render = require(script.Parent.Parent.components.widget.render)
local theme = require(script.Parent.Parent.util.theme)

local source = vide.source
local effect = vide.effect

return ui_labs.CreateVideStory({
	vide = vide,
	controls = {}
}, function(props)

	local tabs = widget.horizontal {
		x = 32, y = 32,
		
		widget.tabs {
			widget.widget {
				title = source("1!"),
				w = 200, h = 200,
				min_w = 150, min_h = 150,

				fn = function()
					return text {
						text = "Hello World!"
					}
				end
			},
		},

		widget.vertical {
			x = 32, y = 32,
			
			widget.tabs {
				widget.widget {
					title = source("1!"),
					w = 200, h = 200,
					min_w = 150, min_h = 150,

					fn = function()
						return text {
							text = "Hello World!"
						}
					end
				},
			},

			widget.tabs {
				widget.widget {
					title = source("2!"),
					w = 200, h = 200,
					min_w = 150, min_h = 150,

					fn = function()
						return text {
							text = "yay!"
						}
					end
				}
			}
		}
	}

	widget.root {
		tabs
	}
	
	return render()

end)
