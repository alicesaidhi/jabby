type namespace = "client" | "server"

export type IncomingConnector = {
	namespace: Player | "server",
	from_vm: number,
	to_vm: number
}

export type OutgoingConnector = {
	namespace: Player | "server",
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

export type SystemId = number

export type SystemTag = "processing" | "finished" | "paused"
export type SystemSettingData = {
	name: string?,
	phase: string?,
	layout_order: number?,
	paused: boolean?
}
export type SystemData = {
	name: string,
	phase: string?,
	layout_order: number,
	paused: boolean
}

type SystemLabel = {}
export type Scheduler = {
	class_name: "Scheduler",
	name: string,

	valid_system_ids: {[SystemId]: true},
	system_data: {[SystemId]: SystemData},
	system_frames: {[SystemId]: {}},

	register_system: (Scheduler, settings: SystemSettingData?) -> SystemId,
	set_system_data: (Scheduler, system: SystemId, settings: SystemSettingData) -> SystemId,
	remove_system: (Scheduler, system: SystemId) -> (),

	mark_system_frame_start: (Scheduler, system: SystemId) -> (),
	mark_system_frame_end: (Scheduler, system: SystemId, s: number?) -> (),
	append_extra_frame_data: (Scheduler, system: SystemId, label: SystemLabel) -> (),
	--- this should call mark_system_frame_start and mark_system_frame_end for you
	run: <T...>(Scheduler, system: SystemId, system: () -> (), T...) -> (),

}

export type Application<T> = {
	class_name: "App",
	name: string,
	icon: string?,

	mount: (props: T, destroy: () -> ()) -> Instance
}

return nil