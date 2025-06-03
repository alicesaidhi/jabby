local jabby_types = require(script.Parent.Parent.Parent.roblox_packages.jabby_types)
local net = require(script.Parent.Parent.net)

return {

	open_client = function(target: jabby_types.Target)
		print("client opened")
		local applets = net.get_registered_applets:invoke(target, nil)
		print("waiting for result")
		applets:after(function(result)
			print(result.ok and result.value or result.why)
		end)

	end

}