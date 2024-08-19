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

return nil