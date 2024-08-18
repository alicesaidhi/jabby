--[[

	net is a utility library designed to handle connections to other actors and
	the server for me.

]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local vm_id = require(script.Parent.vm_id)
local traffic_check = require(script.Parent.traffic_check)

type namespace = "client" | "server"
export type connector = {
	namespace: namespace,
	to: number?,
	from: number?,
	player: Player?,
}

export type NetEvent<T...> = {

	type: "event",

	fire: (any, connector: connector, T...) -> (),
	connect: (any, callback: (connector: connector, T...) -> ()) -> RBXScriptConnection,
}

export type NetCallback<T..., U...> = {

	type: "callback",

	invoke: (any, connector: connector, T...) -> U...,
	set_callback: (any, callback: (connector: connector, T...) -> U...) -> (),
}

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

local function get_remote_function(name: string): RemoteFunction & {
	result: BindableEvent,
	actor: BindableEvent,
}
	if RunService:IsServer() then
		return script:FindFirstChild(name) :: RemoteFunction & {
			result: BindableEvent,
			actor: BindableEvent,
		} or (function()
			local remote = Instance.new("RemoteFunction")
			remote.Name = name
			remote.Parent = script

			local bindable_event = Instance.new("BindableEvent")
			bindable_event.Name = "result"
			bindable_event.Parent = remote

			local fire_actor = Instance.new("BindableEvent")
			fire_actor.Name = "actor"
			fire_actor.Parent = remote
			return remote
		end)() :: RemoteFunction & {
			result: BindableEvent,
			actor: BindableEvent,
		}
	else
		return script:WaitForChild(name) :: RemoteFunction & {
			result: BindableEvent,
			actor: BindableEvent,
		}
	end
end

local function create_event<T...>(name: string, unreliable: boolean?, do_not_block_traffic: boolean?): NetEvent<T...>
	local remote = get_remote_event(name, unreliable)
	local event = {
		type = "event",
	} :: NetEvent<T...>

	local connections = {}

	local function local_fire(...)
		local t = { ... }
		for _, callback in connections :: any do
			-- we have to run this one frame later
			RunService.Heartbeat:Once(function()
				callback(unpack(t))
			end)
		end
	end

	function event:fire(connector: connector, ...)
		local server_to_server = RunService:IsServer() and connector.namespace == "server"
		local client_to_client = RunService:IsClient() and connector.namespace == "client"

		if client_to_client or server_to_server then
			connector = table.clone(connector)
			connector.player = connector.player or Players.LocalPlayer
			connector.from = vm_id

			if connector.to == vm_id then
				local_fire(connector, ...)
				return
			end

			remote.actor:Fire(connector, ...)
		else
			if RunService:IsServer() then
				assert(connector.player, "no player specified")
				local target = connector.player

				connector = table.clone(connector)

				connector.from = vm_id
				connector.player = nil
				remote:FireClient(target, connector, ...)
			else
				connector = table.clone(connector)
				connector.from = vm_id
				remote:FireServer(connector, ...)
			end
		end
	end

	function event:connect(callback: (connector: connector, ...any) -> ())
		local function on_fire(connector: connector, ...)
			if
				connector.to ~= vm_id and connector.to ~= nil
				or RunService:IsServer() and connector.namespace ~= "server"
			then
				return
			end
			assert(
				do_not_block_traffic == true or traffic_check.check(Players.LocalPlayer),
				`{Players.LocalPlayer} tried to fire gorp server`
			)
			callback(connector, ...)
		end

		local connection = remote.actor.Event:Connect(on_fire)

		local t = {
			Disconnect = function()
				connections[connection] = nil
				connection:Disconnect()
			end,
		}

		connections[connection] = on_fire

		return t :: any
	end

	if RunService:IsServer() then
		-- block all traffic from unverified players
		remote.OnServerEvent:Connect(function(player: Player, connector: connector, ...)
			assert(
				do_not_block_traffic == true or traffic_check.check(player),
				`{player} tried to fire gorp server`
			)
			assert(connector.namespace == "server")

			connector.player = player

			if connector.to == vm_id then
				local_fire(connector, ...)
			else
				remote.actor:Fire(connector, ...)
			end
		end)
	else
		remote.OnClientEvent:Connect(function(connector: connector, ...)
			if connector.to == vm_id then
				local_fire(connector, ...)
			else
				remote.actor:Fire(connector, ...)
			end
		end)
	end

	return event
end

local function create_callback<T..., U...>(name: string, do_not_block_traffic: boolean?): NetCallback<T..., U...>
	local remote = get_remote_function(name)
	local callback = {
		type = "callback",
	} :: NetCallback<T..., U...>

	local id = 0
	local current_callback = function(connector: connector, ...: T...): U...
		error("did not specify callback")
	end

	function callback:invoke(connector: connector, ...: T...): U...
		assert(connector.to, "this function requires a target to send to")

		local server_to_server = RunService:IsServer() and connector.namespace == "server"
		local client_to_client = RunService:IsClient() and connector.namespace == "client"

		assert(
			do_not_block_traffic == true or traffic_check.check(Players.LocalPlayer),
			`{Players.LocalPlayer} tried to fire gorp server`
		)
		assert(connector.to, "there must be a target connector")

		connector = table.clone(connector)
		if client_to_client or server_to_server then
			connector.from = connector.from or vm_id
			connector.player = connector.player or Players.LocalPlayer

			if connector.to == vm_id then return current_callback(connector, ...) end

			id += 1
			local stored = id

			local t
			local connection = remote.result.Event:Connect(function(from: number, to: number, id: number, ...)
				if from ~= connector.to then return end
				if to ~= vm_id then return end
				if id ~= stored then return end

				t = { ... }
			end)
			remote.actor:Fire(connector, vm_id, stored, ...)

			-- coroutine.yield breaks stuff
			while t == nil do
				task.wait()
			end

			connection:Disconnect()

			return unpack(t)
		else
			if RunService:IsServer() then
				error("unsecure")
			else
				connector.from = vm_id
				local results = { remote:InvokeServer(connector, ...) }
				return unpack(results)
			end
		end
	end

	function callback:set_callback(callback: (connector: connector, T...) -> U...)
		current_callback = callback :: any
	end

	if RunService:IsServer() then
		remote.OnServerInvoke = function(player, connector, ...)
			assert(
				do_not_block_traffic == true or traffic_check.check(player),
				`{player} tried to invoke gorp server`
			)

			connector.player = player

			local results = { callback:invoke(connector, ...) }
			return unpack(results)
		end
		-- not specifying OnClientInvoke for security reasons
	end

	remote.actor.Event:Connect(function(connector: connector, origin: number, id: number, ...)
		if connector.to ~= vm_id then return end

		local results = { current_callback(connector, ...) }
		connector.from = vm_id
		remote.result:Fire(vm_id, origin, id, unpack(results))
	end)

	return callback
end

return {

	create_callback = create_callback,
	create_event = create_event,
}