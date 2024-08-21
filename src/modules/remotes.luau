local net = require(script.Parent.net)
local types = require(script.Parent.types)

return {

	--[=[
	Broadcasts to clients that a new server has been registered.
	Accepts no params.
	]=]
	new_server_registered = net.create_event("server_registered") :: types.NetEvent<>,

	--[=[
	Broadcasts to servers that a new client has been registered
	Accepts no params.
	]=]
	new_client_registered = net.create_event("client_registered") :: types.NetEvent<>,

	--[=[
	Requests a server to initiate replication of a registry.
	]=]
	request_query = net.create_event("initiate_replicate_registry")

	--[=[
	
	]=]

}