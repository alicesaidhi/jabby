--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local text = require(ReplicatedStorage.src.components.text)
local ui_labs = require(script.Parent.Parent.Parent.roblox_packages.ui_labs)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local widget = require(script.Parent.Parent.components.widget)
local render = require(script.Parent.Parent.components.widget.render)

local source = vide.source

return ui_labs.CreateVideStory({
	vide = vide,
	controls = {}
}, function(props)

	local tabs = widget.horizontal {
		x = 32, y = 32,
		
		widget.tabs {
			widget.widget {
				title = source("Widget 1"),
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
					title = source("Widget 2"),
					w = 200, h = 200,
					min_w = 150, min_h = 150,

					fn = function()
						return text {
							text = "This is a test!"
						}
					end
				},
			},

			widget.tabs {
				widget.widget {
					title = source("Widget 3"),
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
