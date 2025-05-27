-- An applet receives this object which can be used to perform things as an
-- applet.
export type JabbyApplet<Configuration> = {
	read name: string,
	read description: string,
	read configuration: Configuration,
	read unique_id: number,

	read unique_name: (JabbyApplet<Configuration>) -> string,
}

-- An applet needs to conform to this interface
export type JabbyAppletInterface<Configuration> = {
	read name: string,
	read description: string,

	-- When an applet is instantiated by the user, it calls the registered callback
	-- which will be run on the server (note that this is not the actual roblox server)
	read registered: (self: JabbyApplet<Configuration>) -> (),
}

-- The host of an applet.
export type Host = "server" | Player

-- JABBY NETWORKING

-- 

return nil