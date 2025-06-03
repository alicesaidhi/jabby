--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local resizeable_bar = require(ReplicatedStorage.src.components.resizeable_bar)
local ui_labs = require(script.Parent.Parent.Parent.roblox_packages.ui_labs)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local button = require(script.Parent.Parent.components.button)
local container = require(script.Parent.Parent.components.container)
local text = require(script.Parent.Parent.components.text)
local theme = require(script.Parent.Parent.util.theme)

local show = vide.show
local source = vide.source

return ui_labs.CreateVideStory({
	vide = vide,
	controls = {
		accent = false,
		enabled = true
	}
}, function(props)
	local accent = props.controls.accent
	local enabled = props.controls.enabled

    local function field(idx: number)
        local s = source(0)
        return container {
            ws = 1, hs = 1,
            flex = {},

            color = theme.bg(10),
            stroke = theme.bg(-3),

            vide.changed("AbsoluteSize", function(size)
                s(size.X)
            end),

            text {
                text = s
            }
        }
    end

	return container {
		ws = 1, hs = 1,
		flex = { justify = "center", align = "center" },
		
		resizeable_bar {
            ws = 0.8, h = 50,
            fields = source {
                field, field, field, field
            },
            use_offset = source {nil,  100 }
        }
	}

end)
