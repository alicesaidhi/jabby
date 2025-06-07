--[[

jabby_net is the underlying networking abstraction for jabby, alllowing developers
to create networking primitives that can be used to communicate with other clients,
the host or itself.

NOTES:
-1 is intended for global
-2 is intended for redirecting

]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


local gt = require(script.Parent.Parent.roblox_packages.gt)
local jabby_types = require(script.Parent.Parent.roblox_packages.jabby_types)
local jabby_util = require(script.Parent.Parent.roblox_packages.jabby_util)
local call_counter = require(script.Parent.call_counter)
local socket_id = require(script.Parent.socket_id)

local SHOULD_NOT_CREATE_REMOTE_EVENTS = _G.JABBY_DO_NOT_CREATE_REMOTES

local TARGET_INFO = gt.table {
	to = gt.union(gt.isA.Player(), gt.literal("server")),
	id = gt.number({ integer = true, nan = false, range = "[-2, )" }),
}

local TARGET_INFO_CHECKER = gt.build(TARGET_INFO)

local function FUNCTION_INVOKE_TYPE<T>(data: T)
	return gt.table {
		idx = gt.number({ integer = true, nan = false, range = "[0, )" }),
		value = data
	}
end

local function FUNCTION_RESULT_TYPE<T>(data: T)
	return gt.union(
		gt.table {
			idx = gt.number({ integer = true, nan = false, range = "[0, )" }),
			kind = gt.literal("error") :: "error",
			why = gt.string()
		},
		gt.table {
			idx = gt.number({ integer = true, nan = false, range = "[0, )" }),
			kind = gt.literal("ok") :: "ok",
			value = data
		}
	)
end

local SOCKET_INFO = gt.table {
	socket_id = gt.number({ range = "[0,)" }),
	target = gt.union(gt.literal("server") :: "server", gt.isA.Player())
}

local SOCKET_SEND = function<T>(data: T)
	return gt.table {
		id = gt.number( { range = "[0, )"} ),
		data = data
	}
end

type Id = number

export type Sender = jabby_types.Host

export type Target = {
	read to: jabby_types.Host,
	read id: Id,
}

type GenericActionData = {
	user: Sender,
	action: string
}

type EventInstance = {
	read server: RemoteEvent,
	read id2id: BindableEvent,
}

--- @class RemoteConnection

--[=[
@within RemoteConnection
@method on_event
@param fn (Sender, T) -> ()
Sets the callback to run whenever an event is received.

:::warning
This will disable using `:iter()` to iterate over all events in the past frame which may be undesired behavior.
:::
]=]

--[=[
@within RemoteConnection
@method set_permission_data
@param fn (sender: Sender, target: Target, packet: T)
Takes in a function that produces information about what the player is trying to do
with this event. 
]=]

--[=[
@within RemoteConnection
@method iter
@return () -> (Sender, T)
Iterates over all events that have been received in the past frame.
]=]

--[=[
@within RemoteConnection
@method disconnect
Disconnects all connections made.
]=]
export type RemoteConnection<T> = {
	read id: number,
	read namespace: string,
	read identifier: string,
	read typechecker: gt.Type,
	read queue: jabby_util.Queue<Sender, T>,
	
	permissions: {
		redirect: (Sender, Target, T, RemoteConnection<T>) -> boolean,
		process: (Sender, Target, T, RemoteConnection<T>) -> boolean
	},

	callback: (Sender, T) -> (),

	permission_data: (Sender, Target, T) -> GenericActionData,
	event: { RBXScriptConnection },

	read set_permission_data: (RemoteConnection<T>, fn: (Sender, Target, T) -> GenericActionData) -> (),
	read on_event: (RemoteConnection<T>, fn: (sender: Sender, packet: T) -> ()) -> (),
	read iter: (RemoteConnection<T>) -> () -> (Sender, T),
	read disconnect: (RemoteConnection<T>) -> ()
}


--[=[
@class Remote

Allows you to fire an one-way event to a client.
]=]

--[=[
@within Remote
@method fire
@param target { to: number, id: number }
@param packet T

Fires an event to the given target.
]=]

--[=[
@within Remote
@method connect
@return RemoteConnection
Connects to the remote, returning a RemoteConnection
]=]

export type Remote<T> = {
	read namespace: string,
	read identifier: string,
	read typechecker: gt.Type,
	
	permissions: {
		redirect: (Sender, Target, T, RemoteConnection<T>) -> boolean,
		process: (Sender, Target, T, RemoteConnection<T>) -> boolean
	},

	read fire: (Remote<T>, target: Target, value: T) -> (),

	read connect: (Remote<T>, as: Id) -> RemoteConnection<T>
}


--[=[
@class RemoteFnConnection
A bi-directional event allowing you to invoke the server and expect a result back.
]=]

--[=[
@within RemoteFnConnection
@method on_invoke
@param fn (Sender, Packet) -> ReturnPacket
Sets the callback which is used to process the request from the client and to return a result.

:::warning
This will disable using `:iter()` to iterate over all invokes which may be undesired behavior.
:::
]=]

--[=[
@within RemoteFnConnection
@method iter
@return () -> (Sender, (ReturnPacket) -> (), Packet)
Iterates over all invokes that have been received since last iteration and
allows you to return a result if ready.
]=]

export type RemoteFnConnection<T, U> = {
	read id: number,
	read namespace: string,
	read identifier: string,
	read queue: jabby_util.Queue<thread, Sender, T>,

	read invoke_event: RemoteConnection<typeof(FUNCTION_INVOKE_TYPE(newproxy() :: T))>,
	read result_event: Remote<typeof(FUNCTION_RESULT_TYPE(newproxy() :: U))>,

	callback: (Sender, T) -> U,

	read set_permission_data: (RemoteFnConnection<T, U>, fn: (Sender, Target, T) -> GenericActionData) -> (),
	read on_invoke: (RemoteFnConnection<T, U>, fn: (sender: Sender, packet: T) -> U) -> (),
	read iter: (RemoteFnConnection<T, U>) -> () -> (Sender, (U) -> (), T)
}

--[=[
@class RemoteFn
A bi-directional event allowing you to invoke the server and expect a result back.
]=]

--[=[
@within RemoteFn
@method invoke
@param target Target
@param packet Packet
@return Yield<ReturnValue>
Invokes the provided target waiting for a result back.
]=]

--[=[
@within RemoteFn
@method connect
@return RemoteConnection
Connects to the remote, returning a RemoteFnConnection which allows you to handle what to do when invoked.
]=]
export type RemoteFn<T, U> = {
	read namespace: string,
	read identifier: string,
	read pending_from: { [number]: thread },

	read invoke_event: Remote<typeof(FUNCTION_INVOKE_TYPE(newproxy() :: T))>,
	read result_event: Remote<typeof(FUNCTION_RESULT_TYPE(newproxy() :: U))>,

	read invoke: (RemoteFn<T, U>, target: Target, value: T) -> jabby_util.BasicYieldUtil<jabby_util.Result<U>>,

	read connect: (RemoteFn<T, U>, as: Id) -> RemoteFnConnection<T, U>
}

--[=[
@class Socket

Created by RemoteSocket, it implements a basic socket that allows for receiving
and sending data.
]=]

--[=[
@within Socket
@method send
@param Packet unknown

Sends some data to the target.
]=]

--[=[
@within Socket
@method receive
@return () -> unknown

Iterates over all the data that was sent by the target.

:::warning
Iterators will stop when they encounter the first nil value! As result, nil packets cannot be iterated over.
:::
]=]

--[=[
@within Socket
@method on_event
@param fn (unknown) -> ()

Sets the callback which is used to process the event from the client.

:::warning
This will disable using `:receive()` to iterate over all events which may be undesired behavior.
:::
]=]

--[=[
@within Socket
@method status
@return "closed" | "waiting" | "open"

Returns if the socket is closed, waiting or opened.
]=]

--[=[
@within Socket
@method close

Closes the given socket
]=]

export type Socket<T> = {
	read remote: RemoteSocket<T>,

	read socket_id: number,
	read target: Sender,
	read creator: Sender,
	read is_creator: boolean,

	read _talk_remote: Remote<typeof(SOCKET_SEND(newproxy() :: T))>,
	read _talk_receive: RemoteConnection<typeof(SOCKET_SEND(newproxy() :: T))>,
	read _queue: jabby_util.Queue<T>,
	_callback: (T) -> (),

	read status: (Socket<T>) -> "waiting" | "closed" | "open",
	read close: (Socket<T>) -> (),

	read send: (Socket<T>, value: T) -> (),
	read receive: (Socket<T>) -> () -> T,
	read on_event: (Socket<T>, fn: (T) -> ()) -> (),
	-- read on_close: (Socket<T>, fn: (T) -> ()) -> ()
	
}

type SocketRequest = {
	from: Sender,
	to: Target,
	when: number
}

--[=[
@class RemoteSocket

Allow for creating sockets which can be used to transfer data to eachother and skip authority checks.
This should be the preferred method for when you want the server to constantly send a stream of data back.
]=]

--[=[
@within RemoteSocket
@method open_socket
@param target Player | "server"
@return Socket<T>

Opens a new socket that will wait for the target to accept the socket.
]=]

--[=[
@within RemoteSocket
@method accept_socket
@param target Player | "server"
@param id number
@return Socket<T>

Accepts the socket from target with the given id and initiates communication.
This will last until one of the sockets close.
]=]

export type RemoteSocket<T> = {
	read namespace: string,
	read identifier: string,

	read _request_socket: RemoteFn<typeof(SOCKET_INFO), boolean>,
	read _accept_socket: RemoteFn<typeof(SOCKET_INFO), boolean>,
	read _close_socket: Remote<typeof(SOCKET_INFO)>,
	read _talk_socket: Remote<typeof(SOCKET_SEND(newproxy() :: T))>,

	-- sockets that are currently waiting. they map the sender to a map mapping socket ids to the target
	read _waiting_sockets: { [Sender]: { [number]: { target: Sender, when: number } } },
	-- sockets that are currently active. they map the sender to a map mapping socket ids to the target
	read _open_sockets: { [Sender]: { [number]: Sender } },

	read open_socket: (RemoteSocket<T>, target: Sender) -> (Socket<T>, number),
	read accept_socket: (RemoteSocket<T>, target: Sender, id: number) -> Socket<T>,
}

local PACKET_TARGET: jabby_types.Host = if RunService:IsServer() then "server" else Players.LocalPlayer
local REMOTES_LOCATION: Folder

local CAN_USE_THING: ( any ) -> boolean

local function CHECK(data: GenericActionData)
	if data.user == "server" then return true end
	return CAN_USE_THING(data)
end

local get_event do

local function create_remotes_location()
	if REMOTES_LOCATION then return end
	if SHOULD_NOT_CREATE_REMOTE_EVENTS then return end
	if RunService:IsClient() then return end	

	REMOTES_LOCATION = Instance.new("Folder")
	REMOTES_LOCATION.Name = "_JABBY_REMOTES"
	REMOTES_LOCATION.Parent = ReplicatedStorage
end

local function get_remotes_location()
	if REMOTES_LOCATION then return end
	if SHOULD_NOT_CREATE_REMOTE_EVENTS then return end

	REMOTES_LOCATION = ReplicatedStorage:FindFirstChild("_JABBY_REMOTES")
	if not REMOTES_LOCATION then create_remotes_location() end
end


local function create_category(namespace: string)
	if SHOULD_NOT_CREATE_REMOTE_EVENTS then return end
	get_remotes_location()

	if not REMOTES_LOCATION then return end
	if REMOTES_LOCATION:FindFirstChild(namespace) then return end
	if RunService:IsClient() then return end
	
	local folder = Instance.new("Folder")
	folder.Name = namespace
	folder.Parent = REMOTES_LOCATION
end

local function get_category(namespace: string): Folder?
	if SHOULD_NOT_CREATE_REMOTE_EVENTS then return nil end
	
	get_remotes_location()
	create_category(namespace)
	if not REMOTES_LOCATION then return nil end
	return REMOTES_LOCATION:FindFirstChild(namespace) :: Folder
end

local function create_event(namespace: string, name: string): EventInstance?
	if RunService:IsClient() then return nil end
	if SHOULD_NOT_CREATE_REMOTE_EVENTS then return nil end

	local remote = Instance.new("Folder")
	local id2id = Instance.new("BindableEvent")
	local server = Instance.new("RemoteEvent")

	id2id.Name = "id2id"
	server.Name = "server"
	remote.Name = name

	server.Parent = remote
	id2id.Parent = remote
	remote.Parent = get_category(namespace)

	return remote :: any
end

function get_event(namespace: string, name: string): EventInstance?
	if SHOULD_NOT_CREATE_REMOTE_EVENTS then return nil end

	local category = get_category(namespace)
	if not category then return nil end
	
	local remote = category:FindFirstChild(name)
	if not remote and RunService:IsServer() then
		return create_event(namespace, name)
	else
		return remote :: any
	end
end

end

local function set_permission_data<T>(
	self: any,
	fn: (Sender, Target, value: T) -> GenericActionData
)
	self.permission_data = fn
end

local function event_fire<T>(self: Remote<T>, target: Target, value: T)
	self.typechecker:assert(value)
	local event = get_event(self.namespace, self.identifier)
	if not event then 
		print("no event, deferring", self.namespace, self.identifier)
		task.delay(1, event_fire, self, target, value)
		while not event do
			task.wait(1)
			event = get_event(self.namespace, self.identifier)
		end
	end
	assert(event)

	if not TARGET_INFO_CHECKER(target) then error(target) end
	
	if target.to == PACKET_TARGET then
		event.id2id:Fire(PACKET_TARGET, target, value)
	elseif target.to ~= "server" and PACKET_TARGET == "server" then
		event.server:FireClient(target.to, "server", target, value)
	else
		event.server:FireServer(target, value)
	end
end

local function event_on_event<T>(self: RemoteConnection<T>, fn: (Sender, T) -> ())
	self.callback = fn
end

local function event_iter<T>(self: RemoteConnection<T>)
	return self.queue:iter()
end

local function event_disconnect<T>(self: RemoteConnection<T>)
	for _, event in self.event do
		event:Disconnect()
	end

	self.event = {}
end

local function event_connect<T>(self: Remote<T>, id: number): RemoteConnection<T>
	local event = get_event(self.namespace, self.identifier)
	local queue = jabby_util.queue()
	local events = {}
	local object: RemoteConnection<T> = {
		id = id,
		permissions = self.permissions,
		namespace = self.namespace,
		identifier = self.identifier,
		typechecker = self.typechecker,

		queue = queue,
		callback = function(sender: Sender, packet: T)
			queue:add(sender, packet)
		end,
		permission_data = function(sender: Sender, target: Target, data: T)
			return { user = sender, action = "unknown" }
		end,
		
		event = events,

		disconnect = event_disconnect,
		iter = event_iter,
		on_event = event_on_event,
		set_permission_data = set_permission_data
	}

	local function process_event(sender: jabby_types.Host, target: Target, packet: T)
		if not TARGET_INFO_CHECKER(target) then print(sender, target, packet) error(target) end

		if target.to == PACKET_TARGET and target.id == object.id then
			if not self.permissions.process(sender, target, packet, object) then return end
			
			object.callback(sender, packet)
		elseif event and target.to ~= "server" and id == -2 then
			if not self.permissions.redirect(sender, target, packet, object) then return end
			event.server:FireClient(target.to, sender, target, packet)
		end
	end
	
	if RunService:IsServer() and event then
		table.insert(events, event.server.OnServerEvent:Connect(process_event))
		table.insert(events, event.id2id.Event:Connect(process_event))
	elseif event then
		event.server.OnClientEvent:Connect(process_event)
		event.id2id.Event:Connect(process_event)
	end

	return object
end


local function default_permission<T>(sender: Sender, target: Target, packet: T, object: RemoteConnection<T>)
	return CHECK(object.permission_data(sender, target, packet))
end

local CACHED_EVENTS: { [string]: Remote<any> } = {}
local function event_create<T>(namespace: string, identifier: string, gt_type: T)
	local key = `{namespace}:{identifier}`
	if CACHED_EVENTS[key] then return CACHED_EVENTS[key] end

	local self = {
		namespace = namespace,
		identifier = identifier,
		typechecker = gt.build(gt_type),
		permissions = {
			process = default_permission,
			redirect = default_permission
		},

		fire = event_fire,
		connect = event_connect
	}

	if RunService:IsServer() then event_connect(self, -2) end
	CACHED_EVENTS[key] = self
	return self
end

local function function_invoke<T, U>(
	self: RemoteFn<T, U>, 
	target: Target,
	packet: T
): jabby_util.BasicYieldUtil<jabby_util.Result<U>>
	local call_idx = call_counter()
	local yield = jabby_util.yield(function()
		self.pending_from[call_idx] = coroutine.running()
		return coroutine.yield()
	end)
	
	self.invoke_event:fire(target, {
		idx = call_idx,
		value = packet
	})

	return yield :: any
end


local function function_on_invoke<T, U>(
	self: RemoteFnConnection<T, U>, 
	fn: (sender: Sender, packet: T) -> U
)
	self.callback = fn
end

local function function_iter<T, U>(self: RemoteFnConnection<T, U>)
	return self.queue:transform(function(thread: thread, sender: Sender, data: T)
		local function resolve(value)
			coroutine.resume(thread, value)
		end

		return sender, resolve, data
	end)
end

local function function_set_permission_data<T, U>(self: RemoteFnConnection<T, U>, fn: (Sender, Target, T) -> GenericActionData)
	self.invoke_event:set_permission_data(function(sender, target, data)
		return fn(sender, target, data.value)
	end)
end

local function function_connect<T, U>(
	self: RemoteFn<T, U>, 
	id: number
): RemoteFnConnection<T, U>
	local queue = jabby_util.queue()
	local fn_connection = {
		id = id,
		namespace = self.namespace,
		identifier = self.identifier,
		queue = queue,

		invoke_event = self.invoke_event:connect(id),
		result_event = self.result_event,

		callback = function(sender: Sender, packet: T) return packet :: any end,
		permission_info = function(sender: Sender, target: Target, data: T)
			return { user = sender, action = "unknown" }
		end,
		
		set_permission_data = function_set_permission_data,
		on_invoke = function_on_invoke,
		iter = function_iter,
	}

	fn_connection.callback = function(sender: Sender, packet: T)
		print("invoking")
		fn_connection.queue:add(coroutine.running(), sender, packet)
		local value = coroutine.yield()
		return value
	end

	fn_connection.invoke_event:on_event(function(sender, data)
		local result = jabby_util.result.safe(fn_connection.callback, sender, data.value)
		local value = if result.ok then {
			idx = data.idx,
			kind = "ok" :: "ok",
			value = result.value
		} else {
			idx = data.idx,
			kind = "error" :: "error",
			why = tostring(result.why)
		}

		fn_connection.result_event:fire({ to = sender, id = -1 }, value)
	end)

	return fn_connection
end

local CACHED_FUNCTIONS: { [string]: RemoteFn<any, any> } = {}
local function function_create<T, U>(
	namespace: string,
	identifier: string,
	gt_invoke: T,
	gt_result: U
): RemoteFn<T, U>
	local key = `{namespace}:{identifier}`
	if CACHED_FUNCTIONS[key] then return CACHED_FUNCTIONS[key] end
	local allowed_connections = {}

	local self: RemoteFn<T, U> = {
		namespace = namespace,
		identifier = identifier,
		pending_from = {},

		invoke_event = event_create(namespace, `JABBY_{identifier}_invoke`, FUNCTION_INVOKE_TYPE(gt_invoke)),
		result_event = event_create(namespace, `JABBY_{identifier}_result`, FUNCTION_RESULT_TYPE(gt_result)),

		invoke = function_invoke,
		connect = function_connect
	}

	self.invoke_event.permissions.process = function(
		sender: Sender,
		target: Target,
		packet: typeof(FUNCTION_INVOKE_TYPE(newproxy() :: T)),
		object: RemoteConnection<any>
	)
		local allowed = CHECK(object.permission_data(sender, target, packet))

		if not allowed then
			self.result_event:fire({
				to = sender,
				id = -1
			}, {
				idx = packet.idx,
				kind = "error",
				why = "Not allowed"
			})
		end

		return allowed
	end

	self.invoke_event.permissions.redirect = function(
		sender: Sender,
		target: Target,
		packet: typeof(FUNCTION_INVOKE_TYPE(newproxy() :: T)),
		object: RemoteConnection<any>
	)
		local key = `{sender}:{target.to}:{packet.idx}`
		local allowed = CHECK(object.permission_data(sender, target, packet))
		allowed_connections[key] = packet.idx
		return allowed
	end

	self.result_event.permissions.redirect = function(
		sender: Sender,
		target: Target,
		packet: typeof(FUNCTION_RESULT_TYPE(newproxy() :: T)),
		object: RemoteConnection<any>
	)
		local key = `{target.to}:{sender}:{packet.idx}`
		if allowed_connections[key] ~= packet.idx then return false end
		allowed_connections[key] = nil
		return true
	end

	self.result_event:connect(-1):on_event(function(sender, data: typeof(FUNCTION_RESULT_TYPE(newproxy() :: T)))
		local thread = self.pending_from[data.idx]
		if not thread then return end
		self.pending_from[data.idx] = nil

		if data.kind == "ok" then
			coroutine.resume(
				thread,
				jabby_util.result.ok(data.value)
			)
		elseif data.kind == "error" then
			coroutine.resume(
				thread,
				jabby_util.result.fail(data.why)
			)
		end
	end)

	if RunService:IsServer() then function_connect(self, -2) end
	CACHED_FUNCTIONS[key] = self
	return self
end

local function socket_create_waiting_socket(
	socket: RemoteSocket<any>,
	sender: Sender,
	target: Sender,
	socket_id: number
): boolean
	local map_sender_to_waiting_sockets = socket._waiting_sockets[sender] or {} :: never
	if map_sender_to_waiting_sockets[socket_id] then return false end
	if #map_sender_to_waiting_sockets > 10 then return false end
	
	map_sender_to_waiting_sockets[socket_id] = {
		target = target,
		when = os.clock()
	}

	socket._waiting_sockets[sender] = map_sender_to_waiting_sockets
	return true
end

local function socket_open_waiting_socket(
	socket: RemoteSocket<any>,
	sender: Sender,
	target: Sender,
	socket_id: number
): boolean
	local map_sender_to_waiting_sockets = socket._waiting_sockets[sender] or {} :: never
	local map_sender_to_open_sockets = socket._open_sockets[sender] or {} :: never

	if not map_sender_to_waiting_sockets[socket_id] then print("reject socket", socket._waiting_sockets, sender, target); return false end
	if map_sender_to_open_sockets[socket_id] then print("reject socket"); return false end

	socket._waiting_sockets[sender] = map_sender_to_waiting_sockets
	socket._open_sockets[sender] = map_sender_to_open_sockets

	local info = map_sender_to_waiting_sockets[socket_id]

	if info.target ~= target then print("reject socket", info.target, sender); return false end

	map_sender_to_waiting_sockets[socket_id] = nil
	map_sender_to_open_sockets[socket_id] = info.target	
	print("opened socket", socket_id)
	return true
end


local function socket_close_socket(
	socket: RemoteSocket<any>,
	sender: Sender,
	target: Sender,
	socket_id: number
)
	local map_sender_to_waiting_sockets = socket._waiting_sockets[sender] or {} :: never
	local map_sender_to_open_sockets = socket._open_sockets[sender] or {} :: never

	local info = map_sender_to_waiting_sockets[socket_id] and map_sender_to_waiting_sockets[socket_id].target
		or map_sender_to_open_sockets[socket_id]

	if not info or (info ~= target and sender ~= target) then return end
	print("reject socket", debug.traceback());
	map_sender_to_waiting_sockets[socket_id] = nil
	map_sender_to_open_sockets[socket_id] = nil	
end

local function socket_status<T>(socket: Socket<T>): "open" | "closed" | "waiting"
	local map_open_sockets = socket.remote._open_sockets
	local is_open = not not (map_open_sockets[socket.creator] and map_open_sockets[socket.creator][socket.socket_id])
	local map_waiting_sockets = socket.remote._waiting_sockets
	local is_waiting = not not (map_waiting_sockets[socket.creator] and map_waiting_sockets[socket.creator][socket.socket_id])

	print(is_open)
	return if is_open then "open" elseif is_waiting then "waiting" else "closed"
end

local function socket_close<T>(socket: Socket<T>)
	if socket_status(socket) == "closed" then return end
	socket_close_socket(socket.remote, socket.creator, PACKET_TARGET, socket.socket_id)
	socket.remote._close_socket:fire({ to = "server", id = -1 }, { socket_id = socket.socket_id, target = socket.creator })
end

local function socket_send<T>(socket: Socket<T>, value: T)
	socket._talk_remote:fire(
		{ to = socket.target, id = if socket.is_creator then 1 else 0 },
		{ id = socket.socket_id, data = value }
	)
end

local function socket_receive<T>(socket: Socket<T>): () -> T
	return socket._queue:iter()
end

local function socket_on_event<T>(socket: Socket<T>, fn: (T) -> ())
	socket._callback = fn
end

local function socket_handle_receive<T>(
	self: Socket<T>
)
	return function(sender: Sender, packet: typeof(SOCKET_SEND(newproxy() :: T)))
		if sender ~= self.target then return end
		if packet.id ~= self.socket_id then return end

		self._callback(packet.data)
	end
end

local function socket_create_connected_socket<T>(
	socket: RemoteSocket<T>,
	creator: Sender,
	target: Sender,
	is_creator: boolean,
	socket_id: number
): Socket<T>
	local queue = jabby_util.queue()
	
	local self: Socket<T> = {
		remote = socket,

		socket_id = socket_id,
		target = target,
		creator = creator,
		is_creator = is_creator,

		_talk_remote = socket._talk_socket,
		_talk_receive = nil :: any,
		_queue = queue,
		_callback = function(data)
			queue:add(data)
		end,

		status = socket_status,
		close = socket_close,

		send = socket_send,
		receive = socket_receive,
		on_event = socket_on_event
	}

	(self :: any)._talk_receive = socket._talk_socket:connect(if is_creator then 0 else 1):on_event(socket_handle_receive(self))

	return self
end

local function socket_open<T>(socket: RemoteSocket<T>, target: Sender): (Socket<T>, number)
	local id = socket_id()
	
	socket._request_socket:invoke({ to = "server", id = -1 }, {
		socket_id = id,
		target = target
	})

	socket_create_waiting_socket(socket, PACKET_TARGET, target, id)
	return socket_create_connected_socket(socket, PACKET_TARGET, target, true, id), id
end

local function socket_accept<T>(socket: RemoteSocket<T>, from: Sender, id: number): Socket<T>
	socket_create_waiting_socket(socket, from, PACKET_TARGET, id)

	local result = socket._accept_socket:invoke({ to = "server", id = -1 }, {
		socket_id = id,
		target = from
	})

	result:after(function(result)
		if result.ok and result.value then
			socket_open_waiting_socket(socket, from, PACKET_TARGET, id)
		else
			socket_close_socket(socket, from, from, id)
		end
	end)
	
	return socket_create_connected_socket(socket, from, from, false, id)
end

local function socket_create<T>(
	namespace: string,
	identifier: string,
	gt_send: T
): RemoteSocket<T>
	local request_socket = function_create(namespace, `{identifier}_CREATE_SOCKET`, SOCKET_INFO, gt.bool())
	local accept_socket = function_create(namespace, `{identifier}_ACCEPT_SOCKET`, SOCKET_INFO, gt.bool())
	local close_socket = event_create(namespace, `{identifier}_CLOSE_SOCKET`, SOCKET_INFO)
	local talk_socket = event_create(namespace, `{identifier}_TALK_SOCKET`, SOCKET_SEND(gt_send) )

	local waiting_sockets = {}
	local opened_sockets = {}

	local socket: RemoteSocket<T> = {
		namespace = namespace,
		identifier = identifier,

		_request_socket = request_socket,
		_accept_socket = accept_socket,
		_close_socket = close_socket,
		_talk_socket = talk_socket,

		_waiting_sockets = waiting_sockets,
		_open_sockets = opened_sockets,
		
		open_socket = socket_open,
		accept_socket = socket_accept
	}

	if RunService:IsServer() then
		request_socket.invoke_event.permissions.redirect = function()
			return false
		end

		request_socket.result_event.permissions.redirect = function()
			return false
		end

		accept_socket.invoke_event.permissions.redirect = function()
			return false
		end

		accept_socket.result_event.permissions.redirect = function()
			return false
		end

		close_socket.permissions.redirect = function()
			return false
		end

		request_socket.invoke_event.permissions.process = function(_, target: Target)
			return target.id == -1
		end

		request_socket.invoke_event.permissions.process = function(_, target: Target)
			return target.to == "server" and target.id == -1
		end

		close_socket.permissions.process = function(_, target: Target)
			return target.to == "server" and target.id == -1
		end
		
		talk_socket.permissions.process = function(sender: Sender, target: Target, data: Socket<any>)
			local opened = opened_sockets[sender] and opened_sockets[sender][data.socket_id] or opened_sockets[target.to] and opened_sockets[target.to][data.socket_id]
			print(target.id)
			if not opened then return false end
			return (opened == target.to or opened == sender) and target.id == -1
		end

		talk_socket.permissions.redirect = function(sender: Sender, target: Target, data: Socket<any>)
			local opened = opened_sockets[sender] and opened_sockets[sender][data.socket_id] or opened_sockets[target.to] and opened_sockets[target.to][data.socket_id]
			print(target.id)
			if not opened then return false end
			return (opened == target.to or opened == sender) and target.id == -1
		end

		request_socket:connect(-1):on_invoke(function(sender, data)
			print("socket has been requested")
			return socket_create_waiting_socket(socket, sender, data.target, data.socket_id)
		end)
		
		accept_socket:connect(-1):on_invoke(function(sender, data)
			return socket_open_waiting_socket(socket, data.target, sender, data.socket_id)
		end)

		close_socket:connect(-1):on_event(function(sender, data: typeof(SOCKET_INFO))
			socket_close_socket(socket, data.target, sender, data.socket_id)
		end)
	end

	return socket
end

--[=[
@class jabby_net

Responsible for all tasks networking within jabby, allows client-server,
server-client and client-client communication through secure primitives.
]=]

--[=[
@within jabby_net
@function set_auth_callback
@param fn (action: { user: Sender, action: string, [string]: any }) -> boolean

Sets the function that will determine if a user is allowed to fire an event or
not within jabby.
]=]

--[=[
@within jabby_net
@function event_create
@param namespace string
@param identifier string
@external Type https://corecii.github.io/GreenTea/api/Type
@param type Type
@return Remote

Creates a new Remote for sending events.
]=]

--[=[
@within jabby_net
@function function_create
@param namespace string
@param identifier string
@param type_packet Type
@param type_result Type
@return RemoteFn

Creates a new RemoteFn for invokes.
]=]

--[=[
@within jabby_net
@function socket_create
@param namespace string
@param identifier string
@param type Type
@return RemoteSocket

Creates a new RemoteSocket for creating sockets.
]=]

return {
	set_auth_callback = function(fn: (any) -> boolean)
		CAN_USE_THING = fn
	end,

	function_create = function_create,
	event_create = event_create,
	socket_create = socket_create

}