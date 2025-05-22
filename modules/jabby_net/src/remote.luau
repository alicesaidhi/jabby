--[=[

A wrapper around remote events created to allow p2p, server and client communication.

]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local gt = require(script.Parent.packages.gt)
local jabby_core = require(script.Parent.packages.jabby_core)
local jabby_types = require(script.Parent.packages.jabby_types)
local jabby_util = require(script.Parent.packages.jabby_util)

local queue = jabby_util.queue

local SHOULD_NOT_CREATE_REMOTE_EVENTS = _G.JABBY_DO_NOT_CREATE_REMOTES

type SenderInfo = {
	read to: jabby_types.Host,
	read vm: number
}

type TargetInfo = {
	read to: jabby_types.Host,
	read vm: number,
}

type Event = {
	read server: RemoteEvent,
	read vm2vm: BindableEvent,
}

local PACKET_TARGET: jabby_types.Host = if RunService:IsServer() then "server" else Players.LocalPlayer
local REMOTES_LOCATION: Folder

local TARGET_INFO = gt.table {
	to = gt.union(gt.isA.Player, gt.literal("server")),
	vm = gt.number({ integer = true, nan = false, range = "[0, )" })
}

local FUNCTION_INVOKE_INFO = gt.table {
	idx = gt.number({ integer = true, nan = false, range = "[0, )" }),
	value = gt.unknown { allowNil = true }
}

local TARGET_INFO_CHECKER = gt.build(TARGET_INFO)
local FUNCTION_INVOKE_CHECKER = gt.build(FUNCTION_INVOKE_INFO)

local function create_remotes_location()
	if REMOTES_LOCATION then return end
	if SHOULD_NOT_CREATE_REMOTE_EVENTS then return end

	REMOTES_LOCATION = Instance.new("Folder")
	REMOTES_LOCATION.Name = "_JABBY_REMOTES"
	REMOTES_LOCATION.Parent = ReplicatedStorage
end

local function create_category(namespace: string)
	if SHOULD_NOT_CREATE_REMOTE_EVENTS then return end
	if REMOTES_LOCATION:FindFirstChild(namespace) then return end
	
	create_remotes_location()
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

local function create_remote_event<T>(namespace: string, name: string, gt_type: T)
	local pending_packets: jabby_util.Queue<TargetInfo, T> = queue()
	local remote_event: Event
	local middleware: ((sender: SenderInfo, target: TargetInfo, value: T) -> boolean)?
	local typechecker = gt.build(gt_type)

	local packets_to_process: jabby_util.Queue<SenderInfo, T> = queue()

	local function create_event()
		if SHOULD_NOT_CREATE_REMOTE_EVENTS then return end
		if remote_event then return end

		local remote = Instance.new("Folder")
		local vm2vm = Instance.new("BindableEvent")
		local peer2peer = Instance.new("RemoteEvent")

		vm2vm.Name = "vm2vm"
		peer2peer.Name = "server"
		remote.Name = name

		peer2peer.Parent = remote
		vm2vm.Parent = remote
		remote.Parent = get_category(namespace)

		remote_event = remote :: any
	end

	local function get_event()
		if SHOULD_NOT_CREATE_REMOTE_EVENTS then return end

		local category = get_category(namespace)
		if not category then return end
		
		local remote = category:FindFirstChild(name)
		if not remote and RunService:IsServer() then
			create_event()
		else
			remote_event = remote :: any
		end
	end

	local function process_packets()
		get_event()
		if not remote_event then return end

		for target, packet in pending_packets do
			if target.to == PACKET_TARGET and target.vm == jabby_core.vm_id then -- send to local host
				packets_to_process:add(target, packet)
			elseif target.to == PACKET_TARGET and target.vm ~= jabby_core.vm_id then -- send to other vm
				remote_event.vm2vm:Fire(target, packet)
			elseif target.to ~= PACKET_TARGET and PACKET_TARGET == "server" then
				assert(target.to ~= "server")
				remote_event.server:FireClient(target.to, target, packet)
			elseif target.to ~= PACKET_TARGET then
				remote_event.server:FireServer(target, packet)
			end
		end
	end

	local function process_incoming_packet(sender: SenderInfo, target: TargetInfo, packet: T)
		typechecker:assert(packet)
		
		if target.to ~= PACKET_TARGET and PACKET_TARGET == "server" then
			assert(target.to ~= "server")
			remote_event.server:FireClient(target.to, target, packet)
		elseif target.to == PACKET_TARGET and target.vm == jabby_core.vm_id then
			packets_to_process:add(sender, packet)
		end
	end

	local function process_incoming_packet_server(from: Player, sender_vm: number, target: TargetInfo, packet: T)
		if type(sender_vm) ~= "number" then from:Kick() end
		if not TARGET_INFO_CHECKER(target) then from:Kick() end

		local sender: SenderInfo = {
			to = from,
			vm = sender_vm
		}

		if middleware and not middleware(sender, target, packet) then return end

		process_incoming_packet(sender, target, packet)
	end

	local function process_incoming_packet_client(sender_info: SenderInfo, target: TargetInfo, packet: T)
		if not TARGET_INFO_CHECKER(target) then return end

		local sender = sender_info

		if middleware and not middleware(sender, target, packet) then return end

		process_incoming_packet(sender, target, packet)
	end

	remote_event.server.OnServerEvent:Connect(process_incoming_packet_server)
	remote_event.server.OnClientEvent:Connect(process_incoming_packet_client)

	local event = {}

	function event:fire(target_info: TargetInfo, packet: T)
		typechecker:assert(packet)
		pending_packets:add(target_info, packet)
	end

	function event:iter()
		return packets_to_process:iter()
	end

	function event:set_middleware(fn: ((sender: SenderInfo, target: TargetInfo, value: T) -> boolean))
		middleware = fn
	end

	function event:process()
		process_packets()
	end

	return event
end

local function create_remote_function<Send, Result>(namespace: string, name: string, gt_send: Send, gt_result: Result)
	local invoke_event = create_remote_event(namespace, `{name}_JABBYinvokeFN`, FUNCTION_INVOKE_INFO)
	local result_event = create_remote_event(namespace, `{name}_JABBYresultFN`, FUNCTION_INVOKE_INFO)
	--todo: handle errors in the future
	--todo: secure this on the server, implement middleware and prevent exploiters from being able to forward garbage data to others

	local send_typechecker = gt.build(gt_send)
	local result_typechecker = gt.build(gt_result)

	local pending_from: { TargetInfo } = {}
	local pending_results: { { (jabby_util.Result<Result>) -> () } } = {}

	local callback: (sender: SenderInfo, packet: Send) -> Result
	local idx_counter = 0

	local function process_callbacks(call_idx: number, value: Result)
		local callbacks = pending_results[call_idx]
		pending_results[call_idx] = nil

		for _, callback in callbacks do
			callback(jabby_util.result.ok(value) :: any)
		end
	end

	local function process()
		invoke_event:process()
		result_event:process()

		for sender, packet in invoke_event:iter() do
			if not FUNCTION_INVOKE_CHECKER(packet) then continue end
			if not send_typechecker(packet) then continue end

			task.spawn(function()
				local value = callback(sender, packet)
				result_typechecker:assert(value)

				result_event:fire(sender, {
					idx = packet.idx,
					value = value
				})
			end)
		end

		for sender, packet in result_event:iter() do
			if not FUNCTION_INVOKE_CHECKER(packet) then continue end
			if not result_typechecker(packet) then continue end

			local from = pending_from[packet.idx]
			if not from then continue end
			if from.to ~= sender.to or from.vm ~= sender.vm then continue end

			process_callbacks(packet.idx, packet.value)
		end
	end

	local function invoke(target_info: TargetInfo, packet: Send)
		send_typechecker:assert(packet)

		local call_idx = idx_counter; idx_counter += 1

		local result: jabby_util.Result<Result>
		local pending_callbacks = { function(value) result = value end }

		local function await(): jabby_util.Result<Result>
			if result then return result end 

			local thread = coroutine.running()
			local still_waiting = true
			local closure = function()
				if not still_waiting then return end
				coroutine.resume(thread)
			end

			table.insert(pending_callbacks, closure)
			
			coroutine.yield()
			still_waiting = false
			return result or jabby_util.result.fail("Cancelled before a result was returned")
		end
		
		local function after(callback: (jabby_util.Result<Result>) -> ())
			table.insert(pending_callbacks, callback)
		end

		pending_results[call_idx] = pending_callbacks
		invoke_event:fire(target_info, {
			idx = call_idx,
			value = packet
		})
		
		local self = {}

		function self:await()
			return await()
		end

		function self:after(fn: (jabby_util.Result<Result>) -> ())
			after(fn)
			return self
		end
		
		return self
	end

	local self = {}

	function self:invoke(target: TargetInfo, packet: Send)
		return invoke(target, packet)
	end

	function self:set_callback(fn: (from: SenderInfo, Send) -> (Result))
		assert(not callback, "callback already set")
		callback = fn
	end

	function self:process()
		return process()
	end

	return self
end

return {
	create_remote_event = create_remote_event,
	create_remote_function = create_remote_function

}