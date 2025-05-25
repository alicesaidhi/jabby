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

local function create_remote_event<T>(namespace: string, name: string, gt_type: T)
	local remote_event: Event
	local middleware: ((sender: SenderInfo, target: TargetInfo, value: T) -> boolean)?
	local typechecker = gt.build(gt_type)

	local packets_to_process: jabby_util.Queue<SenderInfo, T> = queue()
	local callback = function(sender, t)
		packets_to_process:add(sender, t)
	end

	local function create_event()
		if SHOULD_NOT_CREATE_REMOTE_EVENTS then return end
		if remote_event then return end

		local remote = Instance.new("Folder")
		local id2id = Instance.new("BindableEvent")
		local server = Instance.new("RemoteEvent")

		id2id.Name = "id2id"
		server.Name = "server"
		remote.Name = name

		server.Parent = remote
		id2id.Parent = remote
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

	if RunService:IsServer() then
		get_event()
		remote_event.server.OnServerEvent:Connect(process_incoming_packet_server)
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

export type REvent<T> = typeof(create_remote_event("namespace", "name", 0, newproxy() :: T))

return {
	create_remote_event = create_remote_event,

	PACKET_TARGET = PACKET_TARGET

}