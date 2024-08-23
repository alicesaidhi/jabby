local Players = game:GetService("Players")

local vide = require(script.Parent.Parent.Parent.vide)
local types = require(script.Parent.Parent.modules.types)

return function<T>(app: types.Application<T>, props: T)

	vide.root(function(destroy)
		app.mount(props, destroy).Parent = Players.LocalPlayer.PlayerGui
		return destroy
	end)

end