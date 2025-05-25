--[=[

jabby_net is the underlying networking abstraction for jabby, alllowing developers
to create networking primitives that can be used to communicate with other clients,
the host or itself.

]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


local gt = require(script.Parent.Parent.roblox_packages.gt)
local jabby_types = require(script.Parent.Parent.roblox_packages.jabby_types)
local jabby_util = require(script.Parent.Parent.roblox_packages.jabby_util)
local call_counter = require(script.Parent.call_counter)

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

	read set_permission_data: (RemoteConnection<T>, fn: (Sender, Target, T) -> GenericActionData) -> (),
	read on_event: (RemoteConnection<T>, fn: (sender: Sender, packet: T) -> ()) -> (),
	read iter: (RemoteConnection<T>) -> () -> (Sender, T)
}

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

export type RemoteFn<T, U> = {
	read namespace: string,
	read identifier: string,
	read pending_from: { [number]: thread },
	permission_data: (Sender, Target, T) -> GenericActionData,

	read invoke_event: Remote<typeof(FUNCTION_INVOKE_TYPE(newproxy() :: T))>,
	read result_event: Remote<typeof(FUNCTION_RESULT_TYPE(newproxy() :: U))>,

	read invoke: (RemoteFn<T, U>, target: Target, value: T) -> jabby_util.BasicYieldUtil<jabby_util.Result<U>>,

	read connect: (RemoteFn<T, U>, as: Id) -> RemoteFnConnection<T, U>
}


export type Socket<T> = {
	read namespace: string,
	read identifier: string,
	read typechecker: gt.Type,

	read socket_id: number,
	read target: Target,

	read send: (Socket<T>, value: T) -> (),
	read receive: (Socket<T>) -> () -> T,
	read on_receive: (Socket<T>, fn: (T) -> ()) -> ()
}


type SocketCreate<T> = ((create: true) -> Socket<T>) & ((create: false) -> ())
export type RemoteSocketConnection<T, U> = {
	read id: number,
	read typechecker: gt.Type,

	read on_request: (RemoteFnConnection<T, U>, fn: (sender: Sender, socket: SocketCreate<U>, packet: T) -> ()) -> (),
	read iter: (RemoteFnConnection<T, U>) -> () -> (Sender, SocketCreate<U>, T)
}

export type RemoteSocket<T, U> = {
	read namespace: string,
	read identifier: string,
	read typechecker: (T) -> (boolean, any),

	read fire: (RemoteSocket<T, U>, target: Target, value: T) -> (),
	read set_permission_data: (RemoteConnection<T>, fn: (Sender, Target, T) -> T) -> (),

	read connect: (RemoteSocket<T, U>, as: Id) -> RemoteSocketConnection<T, U>
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

	REMOTES_LOCATION = Instance.new("Folder")
	REMOTES_LOCATION.Name = "_JABBY_REMOTES"
	REMOTES_LOCATION.Parent = ReplicatedStorage
end

local function create_category(namespace: string)
	if SHOULD_NOT_CREATE_REMOTE_EVENTS then return end
	create_remotes_location()
	if REMOTES_LOCATION:FindFirstChild(namespace) then return end
	
	local folder = Instance.new("Folder")
	folder.Name = namespace
	folder.Parent = REMOTES_LOCATION
end

local function get_category(namespace: string): Folder?
	if SHOULD_NOT_CREATE_REMOTE_EVENTS then return nil end
	
	create_remotes_location()
	create_category(namespace)
	return REMOTES_LOCATION:FindFirstChild(namespace) :: Folder
end

local function create_event(namespace: string, name: string): EventInstance?
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
	if not event then return end

	if target.to == PACKET_TARGET then
		event.id2id:Fire(PACKET_TARGET, target, value)
	elseif target.to ~= "server" and PACKET_TARGET == "server" then
		event.server:FireClient(target.to, "server", value)
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

local function event_connect<T>(self: Remote<T>, id: number): RemoteConnection<T>
	local event = get_event(self.namespace, self.identifier)
	local queue = jabby_util.queue()
	local object = {
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

		iter = event_iter,
		on_event = event_on_event,
		set_permission_data = set_permission_data
	}

	local function process_event(sender: jabby_types.Host, target: Target, packet: T)
		TARGET_INFO_CHECKER:assert(target)

		if target.to == "server" and target.id == object.id then
			if not self.permissions.process(sender, target, packet, object) then return end
			
			object.callback(sender, packet)
		elseif event and target.to ~= "server" and id == -2 then
			if not self.permissions.redirect(sender, target, packet, object) then return end
			event.server:FireClient(target.to, target, packet)
		end
	end
	
	if RunService:IsServer() and event then
		event.server.OnServerEvent:Connect(process_event)
		event.id2id.Event:Connect(process_event)
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
	local self = {
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

	self.callback = function(sender: Sender, packet: T)
		self.queue:add(coroutine.running(), sender, packet)
		local value = coroutine.yield()
		return value
	end

	self.invoke_event:on_event(function(sender, data)
		local result = jabby_util.result.safe(self.callback, sender, data.value)
		local value = if result.ok then {
			idx = data.idx,
			kind = "ok" :: "ok",
			value = result.value
		} else {
			idx = data.idx,
			kind = "error" :: "error",
			why = tostring(result.why)
		}

		self.result_event:fire({ to = sender, id = -1 }, value)
	end)

	return self
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

	local self = {
		namespace = namespace,
		identifier = identifier,
		pending_from = {},

		invoke_event = event_create(namespace, `FNJABBY_{identifier}_invoke`, FUNCTION_INVOKE_TYPE(gt_invoke)),
		result_event = event_create(namespace, `FNJABBY_{identifier}_result`, FUNCTION_RESULT_TYPE(gt_result)),

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

return {
	set_auth_callback = function(fn: (any) -> boolean)
		CAN_USE_THING = fn
	end,

	function_create = function_create,
	event_create = event_create

}