--[[

	net is a utility library designed to handle connections to other actors and
	the server for me.

]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local gt = require(ReplicatedStorage.Packages.t)
local signal = require(script.Parent.signal)
local vm_id = require(script.Parent.vm_id)
local traffic_check = require(script.Parent.traffic_check)
local types = require(script.Parent.types)

local local_namespace: "client" | "server" = if RunService:IsClient() then "client" else "server"

local tincoming_connector = gt.build(gt.table({
	namespace = gt.union(gt.literal("server"), gt.literal("client")),
	player = gt.optional(gt.Instance()),
	from_vm = gt.number({integer = true}),
	to_vm = gt.number({integer = true})
}))

local function get_remote_event(name: string, unreliable: boolean?): RemoteEvent & { actor: BindableEvent }
	if RunService:IsServer() then
		return script:FindFirstChild(name) :: RemoteEvent & { actor: BindableEvent }
			or (function()
				local remote = Instance.new(if unreliable then "UnreliableRemoteEvent" else "RemoteEvent")
				remote.Name = name
				remote.Parent = script

				local fire_actor = Instance.new("BindableEvent")
				fire_actor.Name = "actor"
				fire_actor.Parent = remote
				return remote :: RemoteEvent & { actor: BindableEvent }
			end)()
	else
		return script:WaitForChild(name) :: RemoteEvent & { actor: BindableEvent }
	end
end

local function get_remote_function(name: string): RemoteEvent & {
	receive: RemoteEvent,
	result: BindableEvent,
	actor: BindableEvent,
}
	if RunService:IsServer() then
		return script:FindFirstChild(name) :: RemoteEvent & {
			receive: RemoteEvent,
			result: BindableEvent,
			actor: BindableEvent,
		} or (function()
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = script

			local receive = Instance.new("RemoteEvent")
			receive.Name = "receive"
			receive.Parent = remote

			local bindable_event = Instance.new("BindableEvent")
			bindable_event.Name = "result"
			bindable_event.Parent = remote

			local fire_actor = Instance.new("BindableEvent")
			fire_actor.Name = "actor"
			fire_actor.Parent = remote
			return remote
		end)() :: RemoteEvent & {
			receive: RemoteEvent,
			result: BindableEvent,
			actor: BindableEvent,
		}
	else
		return script:WaitForChild(name) :: RemoteEvent & {
			receive: RemoteEvent,
			result: BindableEvent,
			actor: BindableEvent,
		}
	end
end

local function get_incoming_connector(to_vm: number?): types.IncomingConnector
	return table.freeze {
		namespace = local_namespace,
		player = Players.LocalPlayer,
		from_vm = vm_id,
		to_vm = to_vm
	} :: any
end

local function create_event<T...>(name: string, unreliable: boolean?, do_not_block_traffic: boolean?)
	local remote = get_remote_event(name, unreliable)
	local on_event_fire, fire = signal()

	local event = {
		type = "event",

		fire = function(_, connector: types.OutgoingConnector, ...: T...)
			--- if the namespace is within this vm, we can fire it straight to 
			if
				connector.namespace == local_namespace
				and connector.to_vm == vm_id
			then
				local incoming = get_incoming_connector(connector.to_vm)
				fire(incoming, ...)
			--- if the namespace is within this realm, but in a separate actor
			--- we have to fire the actor
			elseif
				connector.namespace == local_namespace
				and connector.to_vm ~= vm_id
			then
				local incoming = get_incoming_connector(connector.to_vm)
				remote.actor:Fire(incoming, ...)
			--- we need to fire a event to a client
			elseif connector.namespace == "client" then
				local incoming = get_incoming_connector(connector.to_vm)
				remote:FireClient(connector.player, incoming, ...)
			--- we need to fire a event to the server
			elseif connector.namespace == "server" then
				local incoming = get_incoming_connector(connector.to_vm)	
				remote:FireServer(incoming, ...)
			end

		end,

		connect = function(callback: (types.IncomingConnector, T...) -> ())
			on_event_fire:connect(callback)
		end
	}

	if RunService:IsServer() then
		remote.OnServerEvent:Connect(function(player, incoming, ...)
			if incoming.to_vm ~= vm_id or incoming.to_vm == nil then return end
			if do_not_block_traffic == false or not traffic_check.check(player) then return end
			if tincoming_connector(incoming) == false then return end
			local incoming: types.IncomingConnector = incoming
			if incoming.namespace ~= "client" then return end
			incoming.player = player

			fire(incoming, ...)
		end)
	else
		remote.OnClientEvent:Connect(function(incoming, ...)
			if incoming.to_vm ~= vm_id or incoming.to_vm == nil then return end
			if tincoming_connector(incoming) == false then return end
			local incoming: types.IncomingConnector = incoming
			if incoming.namespace ~= "server" then return end

			fire(incoming, ...)
		end)
	end

	remote.actor.Event:Connect(function(incoming: types.IncomingConnector, ...)
		if incoming.to_vm ~= vm_id or incoming.to_vm == nil then return end
		fire(incoming, ...)
	end)

	return (event :: any) :: types.NetEvent<T...>
end

local function create_callback<T..., U...>(name: string, do_not_block_traffic: boolean?): types.NetCallback<T..., U...>
	local remote = get_remote_function(name)
	local callback = function(...) return error("no callback set") end
	local class = {
		type = "callback",

		invoke = function(connector: types.OutgoingConnector, ...: T...): U...
			assert(connector.to_vm, "requires a target vm to invoke")

			local incoming_connector = get_incoming_connector(connector.to_vm)

			if
				incoming_connector.namespace == local_namespace
				and incoming_connector.to_vm == vm_id
			then
				--- invoke same vm
				return callback(incoming_connector, ...)
			elseif
				incoming_connector.namespace == local_namespace
				and incoming_connector.to_vm ~= vm_id
			then
				--- invoke another vm
				local guid = HttpService:GenerateGUID(false)
				remote.actor:Fire(incoming_connector, guid, ...)

				--- make a connection
				local tuple

				while true do
					tuple = {remote.result.Event:Wait()}
					if tuple[1] == guid then break end
				end

				return unpack(tuple, 2)
			elseif incoming_connector.namespace == "server" then
				--- invoke another vm
				local guid = HttpService:GenerateGUID(false)
				remote:FireServer(incoming_connector, guid, ...)

				--- make a connection
				local tuple

				while true do
					tuple = {remote.receive.OnClientEvent:Wait() :: any}
					if tuple[1] == guid then break end
				end

				return unpack(tuple, 2)
			elseif incoming_connector.namespace == "client" then
				error("dont invoke the client")
				-- --- invoke another vm
				-- local guid = HttpService:GenerateGUID(false)
				-- remote:FireClient(incoming_connector.player, incoming_connector, guid, ...)

				-- --- make a connection
				-- local tuple

				-- while true do
				-- 	tuple = {remote.receive.OnServerEvent:Wait() :: any}
				-- 	if tuple[2] == guid then break end
				-- end

				-- return unpack(tuple, 2)
			end


		end
	}

	remote.actor.Event:Connect(function(guid, incoming_connector: types.IncomingConnector, ...)
		if typeof(guid) ~= "string" then return end
		if tincoming_connector(incoming_connector) == false then return end

		local tuple = {callback(incoming_connector, ...)}
		remote.result:Fire(guid, unpack(tuple))
	end)

	if RunService:IsServer() then
		remote.OnServerEvent:Connect(function(player, guid, incoming_connector: types.IncomingConnector, ...)
			if typeof(guid) ~= "string" then return end
			if tincoming_connector(incoming_connector) == false then return end
			if do_not_block_traffic == false or not traffic_check.check(player) then return end
			
			local tuple = {callback(incoming_connector, ...)}
			remote.receive:FireClient(player, guid, unpack(tuple))
		end)
	end

	return class :: any
end

return {
	create_callback = create_callback,
	create_event = create_event,
}