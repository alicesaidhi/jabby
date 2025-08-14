local Players = game:GetService "Players"
local RunService = game:GetService "RunService"

local jabby_core =
	require(script.Parent.Parent.Parent.roblox_packages.jabby_core)
local jabby_types =
	require(script.Parent.Parent.Parent.roblox_packages.jabby_types)
local jabby_ui = require(script.Parent.Parent.Parent.roblox_packages.jabby_ui)
local net = require(script.Parent.Parent.net)
local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)

local source = vide.source
local indexes = vide.indexes
local cleanup = vide.cleanup

local function applets_info()
	local store = vide.source({} :: {
		[jabby_types.Host]: {
			applets: {
				{
					name: string,
					description: string,
					id: number,
					client: ModuleScript,
				}
			},
		},
	})

	local function obtain_store_data(host: jabby_types.Host)
		local data =
			net.get_registered_applets:invoke({ to = host, id = 0 }, nil)
		data:after(function(result)
			if not result.ok then return end

			store()[host] = {
				applets = result.value,
			}
			store(store())
		end)
	end

	for _, player in Players:GetPlayers() do
		obtain_store_data(player)
	end

	local n = 0
	cleanup(RunService.Heartbeat:Connect(function(dt)
		n += dt
		if n < 10 then return end
		n = 0

		for _, player in Players:GetPlayers() do
			obtain_store_data(player)
		end
	end))

	obtain_store_data "server"
	cleanup(Players.PlayerRemoving:Connect(function(player)
		store()[player] = nil
		store(store())
	end))

	return jabby_ui.scroll_container {
		ws = 1,
		hs = 1,
		cauto = "y",
		flex = { pad = 8 },
		pad = { p = 12 },

		indexes(store, function(
			value: (
			) -> {
				applets: { { name: string, description: string, id: number } },
			},
			host: jabby_types.Host
		)
			return jabby_ui.container {
				name = "Applet Container",
				ws = 1,
				hs = 0,
				auto = "y",
				flex = { pad = 4 },
				pad = { p = 6 },
				corner = 8,

				stroke = jabby_ui.theme.bg(-1),

				color = jabby_ui.theme.bg(1),

				jabby_ui.text {
					text = `host: {host}`,
				},

				indexes(
					function() return value().applets end,
					function(applet: (
					) -> {
						name: string,
						description: string,
						id: number,
						client: ModuleScript,
					})
						return jabby_ui.button {
							ws = 1,
							hs = 0,

							text = function() return `{applet().name}` end,

							clicked = function()
								jabby_core.open_client(
									applet() :: any,
									{ id = applet().id, to = host }
								)
							end,
						}
					end
				),
			}
		end),
	}
end

return function()
	return jabby_ui.widget.widget {
		title = source "Applets",
		w = 300,
		h = 300,
		min_w = 200,
		min_h = 200,

		fn = applets_info,
	}
end
