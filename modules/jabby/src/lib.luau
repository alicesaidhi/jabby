local jabby_core = require(script.Parent.Parent.roblox_packages.jabby_core)
local jabby_ecs_registry_jecs = require(script.Parent.Parent.roblox_packages.jabby_ecs_registry_jecs)
local jabby_home = require(script.Parent.Parent.roblox_packages.jabby_home)
local jabby_net = require(script.Parent.Parent.roblox_packages.jabby_net)

return {
	applets = {
		jabby_home = jabby_home,
		jabby_ecs_registry = jabby_ecs_registry_jecs,
		world = jabby_ecs_registry_jecs,

		jabbyHome = jabby_home,
		jabbyEcsRegistry = jabby_ecs_registry_jecs,
	},

	register = jabby_core.register_applet,

	set_auth_callback = jabby_net.set_auth_callback,
	setAuthCallback = jabby_net.set_auth_callback
}