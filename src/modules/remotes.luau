local net = require(script.Parent.net)
local types = require(script.Parent.types)

return {

	--[=[
	Broadcasts to clients that a new server has been registered.
	Accepts no params.
	]=]
	new_server_registered = net.create_event("server_registered") :: types.NetEvent<>,

	--[=[
	Pings all servers and make them respond with new_server_registered
	]=]
	ping = net.create_event("ping") :: types.NetEvent<>,

	--[=[
	Broadcasts to servers that a new client has been registered
	Accepts no params.
	]=]
	bind_to_server_core = net.create_event("client_registered") :: types.NetEvent<>,

	--[=[
	Sends a update to a client about a new server
	]=]
	update_server_data =
		net.create_event("update_server_data")
		:: types.NetEvent<{
			worlds: {{id: number, name: string}},
			schedulers: {{id: number, name: string}}	
		}>,

	--[=[
	Requests a server to initiate replication of a registry.
	]=]
	request_query =
		net.create_event("initiate_replicate_registry")
		:: types.NetEvent<number>,

	--[=[
	Requests a server to initiate replication of a scheduler
	]=]
	request_scheduler =
		net.create_event("initiate_replicate_scheduler") ::
		types.NetEvent<number>,

	--[=[
	Updates any static data about systems (like new systems)

	systemid: number
	static_data: {}
	]=]
	scheduler_system_static_update =
		net.create_event("scheduler_system_update_static") ::
		types.NetEvent<number, types.SystemSettingData>,

	--[=[
	Appends a frame to a system
	
	systemid: number
	time_took: number
	]=]
	scheduler_system_update =
		net.create_event("append_frame_system", true) ::
		types.NetEvent<number, number>

}