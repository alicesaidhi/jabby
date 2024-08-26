local traffic_check = require(script.modules.traffic_check)
local vm_id = require(script.modules.vm_id)
local server = require(script.server)
local public = require(script.server.public)
local scheduler = require(script.server.scheduler)

return {

	set_check_function = function(callback: (Player) -> ())
		traffic_check.can_use_jabby = callback 
	end,

	obtain_client = function()
		return require(script.client)
	end,

	vm_id = vm_id,

	public = public,
	scheduler = scheduler,

	broadcast_server = server.broadcast

}