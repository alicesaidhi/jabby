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

return nil