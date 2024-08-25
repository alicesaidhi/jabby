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
	Requests the server to validate a query
	world: number
	query: string
	]=]
	validate_query =
		net.create_event("validate_query")
		:: types.NetEvent<number, string>,

	--[=[
	Result of the validation
	world: number query: string, ok: boolean, message: string?
	]=]
	validate_result =
		net.create_event("validate_result")
		:: types.NetEvent<number, string, boolean, string?>,

	--[=[
	Requests a server to initiate replication of a query.
	
	world: number
	id: number
	query_id: number
	query: string
	]=]
	request_query =
		net.create_event("replicate_query")
		:: types.NetEvent<number, number, string>,

	--[=[
	Disconnects query

	query_id: number
	]=]
	disconnect_query =
		net.create_event("disconnect_query")
		:: types.NetEvent<number>,
	
	--[=[
	Changes the offsets to query for

	query_id: number
	from: number
	to: number
	]=]
	advance_query_page =
		net.create_event("advance_query_page")
		:: types.NetEvent<number, number, number>,

	--[=[
	Updates a single result
	
	query_id: number
	frame: number
	column: number
	row: number
	value: any
	]=]
	update_query_result =
		net.create_event("update_query_result")
		:: types.NetEvent<(number, number, number, number, any)>,

	--[=[
	Requests a server to initiate replication of a scheduler
	]=]
	request_scheduler =
		net.create_event("initiate_replicate_scheduler") ::
		types.NetEvent<number>,

	--[=[
	Requests the server to stop replicating a scheduler
	]=]
	disconnect_scheduler =
		net.create_event("disconnect_replicate_scheduler") ::
		types.NetEvent<number>,

	--[=[
	Updates any static data about systems (like new systems)

	systemid: number
	static_data: {}
	]=]
	scheduler_system_static_update =
		net.create_event("scheduler_system_update_static") ::
		types.NetEvent<number, number, types.SystemData?>,

	--[=[
	Appends a frame to a system
	
	systemid: number
	frame_count: number
	time_took: number
	]=]
	scheduler_system_update =
		net.create_event("append_frame_system", true) ::
		types.NetEvent<number, number, number, number>,

	--[=[
	Pauses a system
	
	scheduler: number
	systemid: number
	paused: boolean
	]=]
	scheduler_system_pause =
		net.create_event("scheduler_pause") ::
		types.NetEvent<number, number, boolean>,

}