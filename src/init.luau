local vm_id = require(script.modules.vm_id)
local server = require(script.server)
local public = require(script.server.public)
local scheduler = require(script.server.scheduler)

return {

	obtain_client = function()
		return require(script.client)
	end,

	vm_id = vm_id,

	public = public,
	scheduler = scheduler,

	

}