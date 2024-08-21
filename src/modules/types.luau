type namespace = "client" | "server"

export type IncomingConnector = {
	namespace: "server",
	from_vm: number,
	to_vm: number
} | {
	namespace: "client",
	player: Player,
	from_vm: number,
	to_vm: number
}

export type OutgoingConnector = {
	namespace: "client",
	player: Player, -- todo: support receiving registries from other players
	to_vm: number? -- not specifying a vm makes it received by all
} | {
	namespace: "server",
	to_vm: number? -- not specifying a vm makes it received by all
}

export type NetEvent<T...> = {

	type: "event",

	fire: (any, connector: OutgoingConnector, T...) -> (),
	connect: (any, callback: (connector: IncomingConnector, T...) -> ()) -> RBXScriptConnection,
}

export type NetCallback<T..., U...> = {

	type: "callback",

	invoke: (any, connector: OutgoingConnector, T...) -> U...,
	set_callback: (any, callback: (connector: IncomingConnector, T...) -> U...) -> (),
}

--todo: maybe we need to rethink the connectors where the Namespace is type Player | "server"?
export type ClientServerInfo = {
	namespace: "client" | "server",
	player: Player,
	vm_id: number,
}


export type SystemId = number

export type SystemTag = "processing" | "finished" | "paused"
export type SystemSettingData = {
	name: string?,
	sort_key: string?,
	layout_order: number?
}

type SystemLabel = {}
export type Scheduler = {

	register_system: (Scheduler) -> SystemId,
	set_system_data: (Scheduler, system: SystemId, settings: SystemSettingData) -> SystemId,
	remove_system: (Scheduler, system: SystemId) -> (),

	--todo: implement a tagging system to allow systems to be tagged with extra
	--		data. this is necessary in order to support pausing systems

	mark_system_frame_start: (Scheduler, system: SystemId) -> (),
	mark_system_frame_end: (Scheduler, system: SystemId, s: number?) -> (),
	append_extra_frame_data: (Scheduler, system: SystemId, label: SystemLabel) -> (),
	--- this should call mark_system_frame_start and mark_system_frame_end for you
	run_system: <T...>(Scheduler, system: SystemId, system: () -> (), T...) -> (),

}

return nil