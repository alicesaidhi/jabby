local Players = game:GetService("Players")

local vide = require(script.Parent.Parent.Parent.vide)
local types = require(script.Parent.Parent.modules.types)

return function<T>(app: types.Application<T>, props: T): () -> ()
	return vide.root(function(destroy)
		local application = app.mount(props, destroy)
		vide.cleanup(application)
		application.Parent = Players.LocalPlayer.PlayerGui
		return destroy
	end)
end