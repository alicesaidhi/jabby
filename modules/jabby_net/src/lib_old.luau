--[[
jabby_net is a thin networking layer for jabby that allows for applets to send
data to other applets.

]]

local RunService = game:GetService("RunService")

local gt = require(script.Parent.Parent.roblox_packages.gt)
local jabby_types = require(script.Parent.Parent.roblox_packages.jabby_types)
local jabby_util = require(script.Parent.Parent.roblox_packages.jabby_util)
local remote = require(script.Parent.remote)

export type SocketTargetInformation = {
	target: remote.TargetInfo,
	idx: number
}

--- Generates information for the packet
type GenericPermissionInfo = {
	user: Player, -- any request from the server will be auto-approved
	action: string,
}

--- A invoke channel is a route for another applet to communicate to this applet and receive a result back
export type AppletInvokeChannelServer<Send, Receive> = {
	channel_name: string,
	kind: "function",

	--- sends a request to the applet, expecting some answer back
	invoke: (AppletInvokeChannelServer<Send, Receive>, Send) -> jabby_util.BasicYieldUtil<Receive>,
	--- sends a request to the applet, expecting some answer back
	set_callback: (AppletInvokeChannelServer<Send, Receive>, fn: () -> Send) -> (),
	--- sets some information about the packet, which will be passed to the permission management function
	set_permission_info: (AppletInvokeChannelServer<Send, Receive>, fn: (sender: remote.SenderInfo, target: remote.TargetInfo, data: Send) -> GenericPermissionInfo) -> AppletInvokeChannelServer<Send, Receive>,
	--- ran whenever a request is received. unique request information refers to where the request came from.
	--- when you want to return a result, call the receive function
	requested: (AppletInvokeChannelServer<Send, Receive>) -> () -> (remote.SenderInfo, (Receive) -> (), Send)
}

--- A invoke channel is a route for another applet to communicate to this applet and receive a result back
export type AppletInvokeChannelClient<Send, Receive> = {
	channel_name: string,
	kind: "function",

	--- sends a request to the applet, expecting some answer back
	invoke: (AppletInvokeChannelClient<Send, Receive>, Send) -> jabby_util.BasicYieldUtil<Receive>,
}


--- A event channel is a route for another applet to send a one-way communication to the applet
export type AppletEventChannelServer<Send> = {
	channel_name: string,
	kind: "event",

	--- fires an event to the applet
	fire: (AppletEventChannelServer<Send>, Send) -> (),
	--- sets some information about the packet, which will be passed to the permission management function
	set_permission_info: (AppletEventChannelServer<Send>, fn: (sender: remote.SenderInfo, target: remote.TargetInfo, data: Send) -> GenericPermissionInfo) -> AppletEventChannelServer<Send>,
	--- ran whenever a request is received. unique request information refers to where the request came from.
	--- when you want to return a result, call the receive function
	requested: (AppletEventChannelServer<Send>) -> () -> (remote.SenderInfo, Send)
}


--- A event channel is a route for another applet to send a one-way communication to the applet
export type AppletEventChannelClient<Send> = {
	channel_name: string,
	kind: "event",

	--- fires an event to the applet
	fire: (AppletEventChannelClient<Send>, Send) -> (),
}

--- Streaming layers are basically a web socket. ps they send data over an unreliable channel
export type AppletSocket<Event> = {
	socket_id: number,
	target: remote.TargetInfo,

	--- fires an event to the applet
	fire: (AppletSocket<Event>, Event) -> (),

	--- closes the socket
	close: (AppletSocket<Event>) -> (),

	--- disconnects the socket
	disconnected: (AppletSocket<Event>) -> boolean,

	--- ran whenever a request is received. unique request information refers to where the request came from.
	--- when you want to return a result, call the receive function
	requested: (AppletSocket<Event>) -> () -> (Event)
}

--- A streaming channel is useful for filtering network traffic 
export type AppletSocketChannelServer<Event, Request> = {
	channel_name: string,
	kind: "stream",
	reliability: "unreliable" | "reliable",

	--- requests a streaming layer to be setup
	request: (AppletSocketChannelServer<Event, Request>, Request) -> (),
	--- sets some information about the packet, which will be passed to the permission management function
	set_permission_info: (AppletSocketChannelServer<Event, Request>, fn: (sender: remote.SenderInfo, target: remote.TargetInfo, data: Request) -> GenericPermissionInfo) -> AppletSocketChannelServer<Event, Request>,
	--- ran whenever a request is received. unique request information refers to where the request came from.
	--- when you want to return a result, call the receive function
	requested: (AppletSocketChannelServer<Event, Request>) -> () -> (remote.SenderInfo, (boolean) -> (), Event)
}

--- A streaming channel is useful for filtering network traffic 
export type AppletSocketChannelClient<Event, Request> = {
	channel_name: string,
	kind: "stream",
	reliability: "unreliable" | "reliable",
	--- requests a streaming layer to be setup
	request: (AppletSocketChannelServer<Event, Request>, Request) -> (),
}

--- The network layer is in charge of keeping all the channels and sockets organized
export type AppletNetworkLayer = {
	name: string,
	id: number,	

	channels: {
		[string]:
			| AppletInvokeChannelServer<unknown, unknown>
			| AppletSocketChannelServer<unknown, unknown>
			| AppletEventChannelServer<unknown>
	},

	get_event: <Event>(AppletNetworkLayer, identifier: string, value: Event) -> AppletEventChannelServer<Event>,
	get_function: <Invoke, Result>(AppletNetworkLayer, identifier: string, invoke: Invoke, result: Result) -> AppletInvokeChannelServer<Invoke, Result>,
	get_socket: <Send, Request>(AppletNetworkLayer, identifier: string, send: Send, request: Request) -> AppletSocketChannelServer<Send, Request>
}

local SOCKET_INFORMATION = gt.union(
	{
		ok = gt.literal(true) :: true,
		socket_id = gt.number({ integer = true })
	},
	{
		ok = gt.literal(false) :: false,
	}
)

local already_warned = false
local GENERAL_USER_CHECKER = function()
	if not already_warned then already_warned = true; warn("please provide your own function for checking permissions to jabby.") end
	return RunService:IsStudio()
end

local function ASSERT_UNIQUE(layer: AppletNetworkLayer, identifier: string)
	local channel = layer.channels[identifier]

	assert(not channel, `channel "{identifier}" on {layer.applet:unique_name()}`)
end

local function noop(): any
	return
end


--[=[
Creates a new remote on a 
]=]
local function create_applet_event<Event>(
	self: AppletNetworkLayer,
	identifier: string,
	gt_type: Event
): AppletEventChannelServer<Event>
	ASSERT_UNIQUE(self, identifier)

	local permission_info
	local channel = {
		applet = self.name,
		channel_name = `identifier`,
		kind = "event",
	}

	local event_channel = remote.create_remote_event(
		self.name,
		`{identifier}_event`,
		self.id,
		gt_type
	)

	function channel:fire(target_info, packet)
		event_channel:fire_as(target_info, self.id, packet)
	end

	-- rejects requests if th e player lacks the appropriate permissions
	function channel:set_permission_info(fn: (remote.SenderInfo, remote.TargetInfo, Event) -> GenericPermissionInfo)
		permission_info = fn
		return self
	end
	
	function channel:requested()
		return event_channel:iter()
	end
	
	event_channel:set_middleware(function(sender, target, packet)
		if not permission_info then warn("cannot collect any data about permissions"); return false end
		return GENERAL_USER_CHECKER(permission_info(sender, target, packet))
	end)

	return channel :: AppletEventChannelServer<Event>	
end


--[=[
Creates a new networking layer on a AppletNetworkLayer
]=]
local function create_applet_function<Invoke, Result>(
	self: AppletNetworkLayer,
	identifier: string,
	gt_send: Invoke,
	gt_result: Result
): AppletInvokeChannelServer<Invoke, Result>
	ASSERT_UNIQUE(self, identifier)
	local channel = {
		channel_name = `identifier`,
		kind = "function",
	}

	local id = self.id
	local invoke_channel = remote.create_remote_function(
		self.name,
		`{identifier}_invoke_callback`,
		self.id,
		gt_send,
		gt_result
	)

	local open_threads: jabby_util.Queue<thread, remote.SenderInfo, Invoke> = jabby_util.queue()
	local permission_info

	local function default_callback(sender: remote.SenderInfo, packet: Invoke): Result
		open_threads:add(coroutine.running(), sender, packet)
		return coroutine.yield()
	end

	function channel:invoke(target: remote.TargetInfo, packet: Invoke)
		return invoke_channel:invoke_as(target, id, packet)
	end

	function channel:set_callback(fn: (remote.SenderInfo, Invoke) -> Result)
		invoke_channel:set_callback(fn)
		return self
	end

	-- rejects requests if the player lacks the appropriate permissions
	function channel:set_permission_info(fn: (remote.SenderInfo, remote.TargetInfo, Invoke) -> GenericPermissionInfo)
		permission_info = fn
		return self
	end

	function channel:requested()
		return open_threads:transform(function(thread: thread, sender: remote.SenderInfo, packet: Result)
			local function resume(data: Result)
				coroutine.resume(thread, packet)
			end

			return resume, sender, packet
		end)
	end

	invoke_channel:set_callback(default_callback)
	invoke_channel:set_middleware(function(sender, target, packet)
		if not permission_info then warn("cannot collect any data about permissions"); return false end
		return GENERAL_USER_CHECKER(permission_info(sender, target, packet))
	end)

	return channel :: AppletInvokeChannelServer<Invoke, Result>
end

--[=[
Creates a new socket channel that allows for connecting to a id and receiving data from them.
After establishing the initial socket, it bypasses certain security checks.
]=]
-- local function create_applet_socket<Send, Request>(
-- 	self: AppletNetworkLayer,
-- 	identifier: string,
-- 	gt_send: Send,
-- 	gt_request: Request
-- ): AppletSocketChannelServer<Send, Request>
-- 	ASSERT_UNIQUE(self, identifier)
	
-- 	local permission_info
-- 	--- maps the sockets a host created to their target
-- 	local map_sender_to_ids: {
-- 		[jabby_types.Host]: {
-- 			[number]: {
-- 				[string]: {
-- 					queue: jabby_util.Queue<Request>,
-- 					target: remote.TargetInfo
-- 				}
-- 			}
-- 		} -- maps host to id to valid sockets to host
-- 	} = {}

-- 	local request_establish_socket = remote.create_remote_function(
-- 		self.name,
-- 		`{identifier}_JABBY_socket_request`,
-- 		self.id,
-- 		gt_request,
-- 		SOCKET_INFORMATION
-- 	)

-- 	local socket_event = remote.create_remote_event(
-- 		self.name,
-- 		`{identifier}_JABBY_socket_event`,
-- 		self.id,
-- 		gt.table {
-- 			idx = gt.number({ integer = true }),
-- 			data = gt_send
-- 		}
-- 	)

-- 	local disconnect_event = remote.create_remote_event(
-- 		self.name,
-- 		`{identifier}_JABBY_socket_disconnect`,
-- 		self.id,
-- 		gt.table {
-- 			idx = gt.number({ integer = true }),
-- 		}
-- 	)

-- 	local channel = {
-- 		channel_name = identifier,
-- 		kind = "stream",
-- 	}

-- 	local open_threads: jabby_util.Queue<thread, remote.SenderInfo, typeof(SOCKET_INFORMATION)> = jabby_util.queue()

-- 	local function default_callback(sender: remote.SenderInfo, packet: Request): typeof(SOCKET_INFORMATION)
-- 		open_threads:add(coroutine.running(), sender, packet)
-- 		return coroutine.yield()
-- 	end

-- 	local function get_unique_socket_id(target: remote.TargetInfo, id: number)
-- 		return `{if target.to == "server" then "server" else target.to.UserId}:{id}`
-- 	end

-- 	--[=[
-- 	Registers a socket from the given person
-- 	]=]
-- 	local function register_socket(sender: remote.SenderInfo, target: remote.TargetInfo, idx: number)
-- 		local map_ids_to_sockets = map_sender_to_ids[sender.to] or {} :: never
-- 		local map_sockets_to_target = map_ids_to_sockets[sender.id] or {} :: never
-- 		map_sender_to_ids[sender.to] = map_ids_to_sockets
-- 		map_ids_to_sockets[sender.id] = map_sockets_to_target
		
-- 		map_sockets_to_target[get_unique_socket_id(target, idx)] = {
-- 			queue = jabby_util.queue(),
-- 			target = target
-- 		}
-- 	end

-- 	--[=[
-- 	Checks if there is an open socket
-- 	]=]
-- 	local function check_open_socket(sender: remote.SenderInfo, target: remote.TargetInfo, idx: number)
-- 		local map_ids_to_sockets = map_sender_to_ids[sender.to]
-- 		if not map_ids_to_sockets then return false end
-- 		local map_sockets_to_target = map_ids_to_sockets[sender.id]
-- 		if not map_sockets_to_target then return false end
-- 		local target_data = map_sockets_to_target[get_unique_socket_id(target, idx)]
-- 		if not target_data then return false end
-- 		return target_data.target.to == target.to and target_data.target.id == target.id
-- 	end

-- 	local function close_socket(sender: remote.SenderInfo, target: remote.SenderInfo, idx: number)
-- 		local map_ids_to_sockets = map_sender_to_ids[target.to]
-- 		if not map_ids_to_sockets then return end
-- 		local map_sockets_to_target = map_ids_to_sockets[target.id]
-- 		if not map_sockets_to_target then return end
-- 		local target_data = map_sockets_to_target[get_unique_socket_id(sender, idx)]
		
-- 		if not target_data then return end
-- 		map_sockets_to_target[get_unique_socket_id(sender, idx)] = nil
-- 		if next(map_sockets_to_target) then return end
-- 		map_ids_to_sockets[target.id] = nil
-- 		if next(map_ids_to_sockets) then return end
-- 		map_sender_to_ids[target.to] = nil
-- 	end

-- 	local function fire(self: AppletSocket<Send>, value: Send)
-- 		socket_event:fire_as(self.target, {
-- 			data = value,
-- 			idx = self.socket_id
-- 		})
-- 	end

-- 	local function requested(self: AppletSocket<Send>, value: Send): () -> Request
-- 		local map_ids_to_sockets = map_sender_to_ids[self.target.to]
-- 		if not map_ids_to_sockets then return noop end
-- 		local map_sockets_to_target = map_ids_to_sockets[self.target.id]
-- 		if not map_sockets_to_target then return noop end
-- 		local target_data = map_sockets_to_target[get_unique_socket_id(LOCAL_TARGET_INFO, self.socket_id)]
-- 		if not target_data then return noop end

-- 		return target_data.queue:iter()
-- 	end

-- 	local function disconnected(self: AppletSocket<Send>)
-- 		return check_open_socket(self.target, LOCAL_TARGET_INFO, self.socket_id)
-- 	end

-- 	local function close(self: AppletSocket<Send>)
-- 		close_socket(self.target, LOCAL_TARGET_INFO, self.socket_id)
-- 		close_socket(LOCAL_TARGET_INFO, self.target, self.socket_id)
-- 	end

-- 	--[=[
-- 	Creates an abstraction over socket_event
-- 	]=]
-- 	local function get_socket_abstraction(target: remote.TargetInfo, idx: number)
-- 		local channel = {
-- 			target = target,
-- 			socket_id = idx,

-- 			fire = fire,
-- 			close = close,
-- 			requested = requested,
-- 			disconnected = disconnected
-- 		}

-- 		return channel
-- 	end

-- 	--[=[
-- 	requests for a socket id from the server
-- 	]=]
-- 	function channel:request(target: remote.TargetInfo, request: Request)
-- 		local function obtain_result(): jabby_util.Result<SocketTargetInformation>
-- 			local is_invoke = request_establish_socket:invoke(target, request):await()
-- 			-- FIXME: this is a subtype of { ok: true, value: number }, seems to be a typechecking bug
-- 			if is_invoke.ok and is_invoke.value.ok then
-- 				register_socket(LOCAL_TARGET_INFO, target, is_invoke.value.socket_id)
-- 				register_socket(target, LOCAL_TARGET_INFO, is_invoke.value.socket_id)
-- 				return result.ok({
-- 					target = target,
-- 					idx = is_invoke.value.socket_id
-- 				})
-- 			else
-- 				return result.fail("Socket request rejected")
-- 			end
-- 		end	

-- 		return jabby_util.yield(obtain_result)	
-- 	end

-- 	--[=[
-- 	creates the socket
-- 	]=]
-- 	function channel:get_socket(target: SocketTargetInformation)
-- 		return get_socket_abstraction(target.target, target.idx)
-- 	end
	
-- 	-- rejects requests if the player lacks the appropriate permissions
-- 	function channel:set_permission_info(fn: (remote.SenderInfo, remote.TargetInfo, Request) -> GenericPermissionInfo)
-- 		permission_info = fn
-- 		return self
-- 	end

-- 	function channel:requested()
-- 		return request_establish_socket
-- 	end

-- 	request_establish_socket:set_middleware(function(sender, target, packet)
-- 		if not permission_info then warn("cannot collect any data about permissions"); return false end
-- 		return GENERAL_USER_CHECKER(permission_info(sender, target, packet))
-- 	end)

-- 	request_establish_socket:set_result_middleware(function(sender, target, packet)
-- 		if packet.ok then
-- 			register_socket(sender, target, packet.socket_id)
-- 			register_socket(target, sender, packet.socket_id)
-- 		end

-- 		return true
-- 	end)

-- 	socket_event:set_callback(function(sender, packet)
-- 		local map_ids_to_sockets = map_sender_to_ids[sender.to]
-- 		if not map_ids_to_sockets then return end
-- 		local map_sockets_to_target = map_ids_to_sockets[sender.id]
-- 		if not map_sockets_to_target then return end
-- 		local target_data = map_sockets_to_target[get_unique_socket_id(LOCAL_TARGET_INFO, packet.idx)]
-- 		if not target_data then return end
-- 		target_data.queue:add(packet.data)
-- 	end)

-- 	disconnect_event:set_callback(function(sender, packet)
-- 		close_socket(sender, LOCAL_TARGET_INFO, packet.idx)
-- 		close_socket(LOCAL_TARGET_INFO, sender, packet.idx)
-- 	end)
	
-- 	disconnect_event:set_middleware(function(sender, target, packet)
-- 		return check_open_socket(sender, target, packet.idx)
-- 	end)

-- 	socket_event:set_middleware(function(sender, target, packet)
-- 		return check_open_socket(sender, target, packet.idx)
-- 	end)

-- 	return channel :: AppletSocketChannelServer<Send, Request>
-- end

local function get_applet_event<Event>(
	self: AppletNetworkLayer,
	identifier: string,
	gt_type: Event
): AppletEventChannel<Event>
	local channel = self.channels[identifier]
	if channel then
		assert(channel.kind == "event", "not event")
		return channel
	else
		return create_applet_event(self, identifier, gt_type)
	end
end

local function get_applet_function<Invoke, Result>(
	self: AppletNetworkLayer,
	identifier: string,
	gt_send: Invoke,
	gt_result: Result
): AppletInvokeChannel<Invoke, Result>
local channel = self.channels[identifier]
	if channel then
		assert(channel.kind == "function", "not function")
		return channel
	else
		return create_applet_function(self, identifier, gt_send, gt_result)
	end
end


-- local function get_applet_socket<Event, Request>(
-- 	self: AppletNetworkLayer,
-- 	identifier: string,
-- 	gt_event: Event,
-- 	gt_request: Request
-- ): AppletStreamingChannel<Event, Request>
-- 	local channel = self.channels[identifier]
-- 	if channel then
-- 		assert(channel.kind == "stream", "not socket channel")
-- 		return channel
-- 	else
-- 		return create_applet_socket(self, identifier, gt_event, gt_request)
-- 	end
-- end

local function create_applet_layer(applet: jabby_types.JabbyApplet<any>): AppletNetworkLayer
	local applet_layer = {
		name = applet.name,
		id = applet.unique_id,
		channels = {},

		get_event = get_applet_event,
		get_function = get_applet_function,
		get_socket = get_applet_socket
	}

	return applet_layer
end

local function get_applet_layer(name: string, id: number): AppletNetworkLayer
	local applet_layer = {
		name = name,
		id = id,
		channels = {},

		get_event = get_applet_event,
		get_function = get_applet_function,
		get_socket = get_applet_socket
	}

	return applet_layer
end

return {
	create_applet_layer = create_applet_layer,
	get_applet_layer = get_applet_layer,
	
}
