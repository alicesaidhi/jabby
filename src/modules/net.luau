--[[

	net is a utility library designed to handle connections to other actors and
	the server for me.

]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local gt = require(script.Parent.Parent.Parent.t)
local signal = require(script.Parent.signal)
local vm_id = require(script.Parent.vm_id)
local traffic_check = require(script.Parent.traffic_check)
local types = require(script.Parent.types)

local local_host: "server" | Player
local MANAGER_VM = 0

if RunService:IsServer() then
	local_host = "server"
else
	local_host = Players.LocalPlayer
end

local tincoming_connector = gt.build(gt.table({
	host = gt.union(gt.literal("server"), gt.Instance()),
	from_vm = gt.number({integer = true}),
	to_vm = gt.optional(gt.number({integer = true}))
}))

local function get_remote_event(name: string, unreliable: boolean?): RemoteEvent & { actor: BindableEvent, peer: RemoteEvent }
	if RunService:IsServer() then
		return script:FindFirstChild(name) :: RemoteEvent & { actor: BindableEvent }
			or (function()
				local remote = Instance.new(if unreliable then "UnreliableRemoteEvent" else "RemoteEvent")
				remote.Name = name
				remote.Parent = script

				local fire_actor = Instance.new("BindableEvent")
				fire_actor.Name = "actor"
				fire_actor.Parent = remote
				
				local peer = Instance.new("RemoteEvent")
				peer.Name = "peer"
				peer.Parent = remote

				return remote :: RemoteEvent & { actor: BindableEvent, peer: RemoteEvent }
			end)()
	else
		return script:WaitForChild(name) :: RemoteEvent & { actor: BindableEvent }
	end
end

local function create_event<T...>(name: string, unreliable: boolean?, do_not_block_traffic: boolean?)
	local remote = get_remote_event(name, unreliable)
	local on_event_fire, fire = signal()

	local event = {
		type = "event",

		fire = function(_, connector: types.OutgoingConnector, ...)
			--- if the host is within this vm, we can fire it straight to
			if not traffic_check.check(local_host, connector.host, true) then
				-- print("cancel fire!", remote.Name)
				return
			end
			
			if
				connector.host == local_host
				and connector.to_vm == vm_id
			then

				local incoming = {
					host = local_host,
					from_vm = vm_id,
					to_vm = connector.to_vm
				}

				fire(incoming, ...)
			--- if the host is the same, but in a separate actor
			--- we have to fire the actor
			elseif
				connector.host == local_host
				and connector.to_vm ~= vm_id
			then
				local incoming = {
					host = local_host,
					from_vm = vm_id,
					to_vm = connector.to_vm
				}

				remote.actor:Fire(incoming, ...)
			--- we need to fire the server
			elseif connector.host == "server" then
				local incoming = {
					host = "server",
					from_vm = vm_id,
					to_vm = connector.to_vm
				}

				remote:FireServer(incoming, ...)
			--- we need to fire the client
			elseif local_host == "server" then
				local incoming = {
					host = "server",
					from_vm = vm_id,
					to_vm = connector.to_vm
				}

				remote:FireClient(connector.host, incoming, ...)
			--- we need to tell the server to redirect this to the client
			else
				local incoming = {
					host = connector.host,
					from_vm = vm_id,
					to_vm = connector.to_vm
				}

				remote:FireServer(incoming, ...)
			end

		end,

		connect = function(_, callback: (types.IncomingConnector, T...) -> ())
			on_event_fire:connect(callback :: any)
		end
	}

	if RunService:IsServer() then
		remote.OnServerEvent:Connect(function(player, target: types.IncomingConnector, ...)
			--- check if the player is allowed to send this
			if not do_not_block_traffic and not traffic_check.check(player, target.host) then
				print("cancel!", remote.Name)
				return
			end

			--- check if its a proper connector
			if not tincoming_connector(target) then return end
	
			if target.host == "server" and (target.to_vm == vm_id or target.to_vm == nil) then
				target.host = player
				fire(target, ...)
			elseif target.host ~= "server" and vm_id == MANAGER_VM then
				local to = target.host
				target.host = player
				remote:FireClient(
					to,
					target,
					...
				)
			end
		end)
	else
		remote.OnClientEvent:Connect(function(incoming: types.IncomingConnector, ...)
			-- print("receive", remote.Name, "from", incoming.host)
			if tincoming_connector(incoming) == false then return end
			if incoming.to_vm ~= vm_id and incoming.to_vm ~= nil then return end
			traffic_check._whitelist(local_host, incoming.host)

			fire(incoming, ...)
		end)
	end

	remote.actor.Event:Connect(function(incoming: types.IncomingConnector, ...)
		if incoming.to_vm ~= vm_id and incoming.to_vm ~= nil then return end
		fire(incoming, ...)
	end)

	return (event :: any) :: types.NetEvent<T...>
end

-- local function create_callback<T..., U...>(name: string, do_not_block_traffic: boolean?): types.NetCallback<T..., U...>
-- 	local remote = get_remote_function(name)
-- 	local callback = function(...) return error("no callback set") end
-- 	local class = {
-- 		type = "callback",

-- 		invoke = function(connector: types.OutgoingConnector, ...: T...): U...
-- 			assert(connector.to_vm, "requires a target vm to invoke")

-- 			if
-- 				incoming_connector.host == local_host
-- 				and incoming_connector.to_vm == vm_id
-- 			then
-- 				--- invoke same vm
-- 				return callback(incoming_connector, ...)
-- 			elseif
-- 				incoming_connector.host == local_host
-- 				and incoming_connector.to_vm ~= vm_id
-- 			then
-- 				--- invoke another vm
-- 				local guid = HttpService:GenerateGUID(false)
-- 				remote.actor:Fire(incoming_connector, guid, ...)

-- 				--- make a connection
-- 				local tuple

-- 				while true do
-- 					tuple = {remote.result.Event:Wait()}
-- 					if tuple[1] == guid then break end
-- 				end

-- 				return unpack(tuple, 2)
-- 			elseif incoming_connector.host == "server" then
-- 				--- invoke another vm
-- 				local guid = HttpService:GenerateGUID(false)
-- 				remote:FireServer(incoming_connector, guid, ...)

-- 				--- make a connection
-- 				local tuple

-- 				while true do
-- 					tuple = {remote.receive.OnClientEvent:Wait() :: any}
-- 					if tuple[1] == guid then break end
-- 				end

-- 				return unpack(tuple, 2)
-- 			elseif incoming_connector.host == "client" then
-- 				error("dont invoke the client")
-- 				-- --- invoke another vm
-- 				-- local guid = HttpService:GenerateGUID(false)
-- 				-- remote:FireClient(incoming_connector.player, incoming_connector, guid, ...)

-- 				-- --- make a connection
-- 				-- local tuple

-- 				-- while true do
-- 				-- 	tuple = {remote.receive.OnServerEvent:Wait() :: any}
-- 				-- 	if tuple[2] == guid then break end
-- 				-- end

-- 				-- return unpack(tuple, 2)
-- 			end


-- 		end
-- 	}

-- 	remote.actor.Event:Connect(function(guid, incoming_connector: types.IncomingConnector, ...)
-- 		if typeof(guid) ~= "string" then return end
-- 		if tincoming_connector(incoming_connector) == false then return end

-- 		local tuple = {callback(incoming_connector, ...)}
-- 		remote.result:Fire(guid, unpack(tuple))
-- 	end)

-- 	if RunService:IsServer() then
-- 		remote.OnServerEvent:Connect(function(player, guid, incoming_connector: types.IncomingConnector, ...)
-- 			if typeof(guid) ~= "string" then return end
-- 			if tincoming_connector(incoming_connector) == false then return end
-- 			if do_not_block_traffic == false or not traffic_check.check(player) then return end
			
-- 			local tuple = {callback(incoming_connector, ...)}
-- 			remote.receive:FireClient(player, guid, unpack(tuple))
-- 		end)
-- 	end

-- 	return class :: any
-- end

return {
	-- create_callback = create_callback,
	create_event = create_event,
	local_host = local_host
}