local jabby_core = require(script.Parent.Parent.Parent.roblox_packages.jabby_core)
local jabby_types = require(script.Parent.Parent.Parent.roblox_packages.jabby_types)
local jabby_ui = require(script.Parent.Parent.Parent.roblox_packages.jabby_ui)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)

local source = vide.source
local indexes = vide.indexes

local function applets_info(applets: () -> { [jabby_types.Host]: { applets: {{ name: string, description: string, id: number }} } })
	return function()
		return jabby_ui.scroll_container {
			ws = 1, hs = 1, cauto = "y",
			flex = { pad = 8 }, pad = { p = 12 },

			indexes(applets, function(value: () -> { ms: () -> number, applets: {{ name: string, description: string, id: number }} }, host: jabby_types.Host)
				return jabby_ui.container {
					name = "Applet Container",
					ws = 1, hs = 0,
					auto = "y",
					flex = { pad = 4 }, pad = { p = 6 },
					corner = 8,

					stroke = jabby_ui.theme.bg(-1),

					color = jabby_ui.theme.bg(1),

					jabby_ui.text {
						text = `host: {host}`,
					},

					indexes(function()
						return value().applets
					end, function(applet: () -> { name: string, description: string, id: number, client: ModuleScript })
						return jabby_ui.button {
							ws = 1, hs = 0,
							
							text = function()
								return `{applet().name}`
							end,

							clicked = function()
								jabby_core.open_client(applet() :: any, { id = applet().id, to = host })
							end
						}
					end)
				}
			end)

		}
	end
end

return function(applets: () -> { [jabby_types.Host]: { applets: {{ name: string, description: string, id: number }} } })
	return jabby_ui.widget.widget {
		title = source("Applets"),
		w = 300, h = 300,
		min_w = 200, min_h = 200,

		fn = applets_info(applets)
	}
end