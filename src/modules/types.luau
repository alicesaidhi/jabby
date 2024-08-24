type host = "client" | "server"

export type IncomingConnector = {
	host: Player | "server",
	from_vm: number,
	to_vm: number
}

export type OutgoingConnector = {
	host: Player | "server",
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

export type SystemLabel = {}

export type SystemFrame = {
	i: number,
	s: number
}

export type Scheduler = {
	class_name: "Scheduler",
	name: string,

	valid_system_ids: {[SystemId]: true},
	system_data: {[SystemId]: SystemData},
	system_data_updated: {[SystemId]: true},
	system_frames: {[SystemId]: SystemFrame},
	system_frames_updated: {[SystemId]: {[SystemFrame]: true}},

	register_system: (Scheduler, settings: SystemSettingData?) -> SystemId,
	set_system_data: (Scheduler, system: SystemId, settings: SystemSettingData) -> SystemId,
	remove_system: (Scheduler, system: SystemId) -> (),

	mark_system_frame_start: (Scheduler, system: SystemId) -> (),
	mark_system_frame_end: (Scheduler, system: SystemId, s: number?) -> (),
	-- append_extra_frame_data: (Scheduler, system: SystemId, label: SystemLabel) -> (),
	--- this should call mark_system_frame_start and mark_system_frame_end for you
	run: <T...>(Scheduler, system: SystemId, system: () -> (), T...) -> (),

}

export type Application<T> = {
	class_name: "app",
	name: string,

	mount: (props: T, destroy: () -> ()) -> Instance
}

return nil