--[=[

A wrapper around remote events created to allow p2p, server and client communication.

]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local gt = require(script.Parent.Parent.roblox_packages.gt)
local jabby_types = require(script.Parent.Parent.roblox_packages.jabby_types)
local jabby_util = require(script.Parent.Parent.roblox_packages.jabby_util)
local call_counter = require(script.Parent.call_counter)

local queue = jabby_util.queue

local SHOULD_NOT_CREATE_REMOTE_EVENTS = _G.JABBY_DO_NOT_CREATE_REMOTES

export type SenderInfo = {
	read to: jabby_types.Host,
	read id: number
}

export type TargetInfo = {
	read to: jabby_types.Host,
	read id: number,
}

export type Event = {
	read server: RemoteEvent,
	read id2id: BindableEvent,
}

local PACKET_TARGET: jabby_types.Host = if RunService:IsServer() then "server" else Players.LocalPlayer
local REMOTES_LOCATION: Folder

local TARGET_INFO = gt.table {
	to = gt.union(gt.isA.Player(), gt.literal("server")),
	id = gt.number({ integer = true, nan = false, range = "[0, )" }),
}

local TARGET_INFO_CHECKER = gt.build(TARGET_INFO)

local function FUNCTION_INVOKE_INFO<T>(data: T)
	return gt.table {
		idx = gt.number({ integer = true, nan = false, range = "[0, )" }),
		value = data
	}
end

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

local function create_remote_event<T>(namespace: string, name: string, id: number?, gt_type: T)
	local remote_event: Event
	local middleware: ((sender: SenderInfo, target: TargetInfo, value: T) -> boolean)?
	local typechecker = gt.build(gt_type)

	local packets_to_process: jabby_util.Queue<SenderInfo, T> = queue()
	local callback = function(sender, t)
		packets_to_process:add(sender, t)
	end

	

	local function process_incoming_packet(sender: SenderInfo, target: TargetInfo, packet: T)
		typechecker:assert(packet)
		
		if target.to ~= PACKET_TARGET and PACKET_TARGET == "server" then
			assert(target.to ~= "server")
			remote_event.server:FireClient(target.to, target, packet)
		elseif target.to == PACKET_TARGET and (target.id == id or id == nil) then
			callback(sender, packet)
		end
	end

	local function process_incoming_packet_server(from: Player, sender_id: number, target: TargetInfo, packet: T)
		if type(sender_id) ~= "number" then from:Kick() end
		if not TARGET_INFO_CHECKER(target) then from:Kick() end

		local sender: SenderInfo = {
			to = from,
			id = sender_id
		}

		if middleware and not middleware(sender, target, packet) then return end

		process_incoming_packet(sender, target, packet)
	end

	local function process_incoming_packet_client(sender: SenderInfo, target: TargetInfo, packet: T)
		if not TARGET_INFO_CHECKER(target) then return end
		if not TARGET_INFO_CHECKER(sender) then return end
		if middleware and not middleware(sender, target, packet) then return end

		process_incoming_packet(sender, target, packet)
	end

	get_event()
	if RunService:IsServer() and RunService:IsRunning() and remote_event then
		remote_event.server.OnServerEvent:Connect(process_incoming_packet_server)
		remote_event.id2id.Event:Connect(process_incoming_packet_client)
	end

	if RunService:IsClient() and RunService:IsRunning() and remote_event then
		remote_event.server.OnClientEvent:Connect(process_incoming_packet_client)
		remote_event.id2id.Event:Connect(process_incoming_packet_client)
	end

	local event = {}

	function event:fire_as(target: TargetInfo, id: number, packet: T)
		typechecker:assert(packet)
		if target.to == PACKET_TARGET then -- send to other id
			remote_event.id2id:Fire({ to = PACKET_TARGET, id = id }, target, packet)
		elseif target.to ~= PACKET_TARGET and PACKET_TARGET == "server" then
			assert(target.to ~= "server")
			remote_event.server:FireClient(
				target.to,
				{ to = PACKET_TARGET, id = id }, 
				target,
				packet
			)
		elseif target.to ~= PACKET_TARGET then
			remote_event.server:FireServer(id, target, packet)
		end
	end

	function event:set_callback(fn: (SenderInfo, T) -> ())
		callback = fn
	end

	function event:iter()
		return packets_to_process:iter()
	end

	function event:set_middleware(fn: ((sender: SenderInfo, target: TargetInfo, value: T) -> boolean))
		middleware = fn
	end

	return event
end

--[=[
Creates a remote function inside namespace with name.
The given id is a filter, used to block cert
]=]
local function create_remote_function<Send, Result>(namespace: string, name: string, id: number, gt_send: Send, gt_result: Result)
	local invoke_event = create_remote_event(namespace, `{name}_JABBYinvokeFN`, id, FUNCTION_INVOKE_INFO(gt_send))
	local result_event = create_remote_event(namespace, `{name}_JABBYresultFN`, nil, FUNCTION_INVOKE_INFO(gt_result))
	-- todo: handle errors in the future
	-- todo: secure this on the server
	-- todo: prevent exploiters from invoking events

	local send_typechecker = gt.build(gt_send)
	local result_typechecker = gt.build(gt_result)

	local pending_from: { TargetInfo } = {}
	local pending_results: { thread } = {}

	local callback: (sender: SenderInfo, packet: Send) -> Result

	local function process_callbacks(call_idx: number, value: Result)
		local thread = pending_results[call_idx]
		pending_results[call_idx] = nil

		if coroutine.status(thread) == "dead" then return end
		coroutine.resume(thread, jabby_util.result.ok(value))
	end

	local function process_incoming_invoke(sender: SenderInfo, packet: typeof(FUNCTION_INVOKE_INFO(gt_send)))
		if not send_typechecker(packet) then return end

		local value = callback(sender, packet.value)
		result_typechecker:assert(value)

		result_event:fire_as(sender, id, {
			idx = packet.idx,
			value = value
		})
	end

	local function process_outgoing_invoke(sender: SenderInfo, packet: typeof(FUNCTION_INVOKE_INFO(gt_result)))
		if not result_typechecker(packet) then return end

		local from = pending_from[packet.idx]
		if not from then return end
		if from.to ~= sender.to or from.id ~= sender.id then return end

		process_callbacks(packet.idx, packet.value)
	end

	invoke_event:set_callback(process_incoming_invoke)
	result_event:set_callback(process_outgoing_invoke)

	local function invoke(target: TargetInfo, id: number, packet: Send)
		send_typechecker:assert(packet)

		local call_idx = call_counter()
		local yield: jabby_util.BasicYieldUtil<jabby_util.Result<Result>> = jabby_util.yield(function()
			pending_results[call_idx] = coroutine.running()
			local data = coroutine.yield() :: any
			return data
		end)

		pending_from[call_idx] = target
		invoke_event:fire_as(target, id, {
			idx = call_idx,
			value = packet
		})
		
		return yield
	end

	local self = {}

	function self:invoke_as(target: TargetInfo, id: number, packet: Send)
		return invoke(target, id, packet)
	end

	function self:set_callback(fn: (from: SenderInfo, Send) -> (Result))
		assert(not callback, "callback already set")
		callback = fn
	end

	function self:set_middleware(fn: (from: SenderInfo, TargetInfo, Send) -> (boolean))
		invoke_event:set_middleware(fn)
	end

	function self:set_result_middleware(fn: (from: SenderInfo, TargetInfo, Result) -> (boolean))
		result_event:set_middleware(fn)
	end
	
	return self
end

export type REvent<T> = typeof(create_remote_event("namespace", "name", 0, newproxy() :: T))
export type RFunc<I, R> = typeof(create_remote_function("namespace", "name", 0, newproxy() :: I, newproxy() :: R))

return {
	create_remote_event = create_remote_event,
	create_remote_function = create_remote_function,

	PACKET_TARGET = PACKET_TARGET

}