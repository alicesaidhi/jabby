-- An applet receives this object which can be used to perform things as an
-- applet.

--[=[
@class JabbyApplet

Contains information about the applet including the name of the applet,
a description, the configuration values passed into it and a unique id which can
be used for networking.
]=]

--[=[
@within JabbyApplet
@prop name string
@readonly

The name of the applet that was registered. This is defined by the interface.
]=]

--[=[
@within JabbyApplet
@prop description string
@readonly

The description of the applet that was registered. This is defined by the interface.
]=]

--[=[
@within JabbyApplet
@prop configuration unknown
@readonly

A user-provided configuration of the applet. This is provided when creating the
applet through `jabby_core.register_applet`
]=]

--[=[
@within JabbyApplet
@prop unique_id number
@readonly

A unique identifier for the applet separating it from every other actor on the
client / server. Note that this is not unique between server, client or other
clients. It's used to separate traffic for jabby networking.
]=]
export type JabbyApplet<Configuration> = {
	read name: string,
	read description: string,
	read configuration: Configuration,
	read unique_id: number,
}

--[=[
@class JabbyAppletInterface

This interface is passed to the register function to register a new applet.
Currently, we only expect the registered function which is immediately called
to initiate the applet.
]=]

--[=[
@within JabbyAppletInterface
@prop name string
The name of the applet you're registering
]=]

--[=[
@within JabbyAppletInterface
@prop description string
Describes the applet on what it does.
]=]

--[=[
@within JabbyAppletInterface
@prop registered (data: JabbyApplet<Configuration>) -> ()
Called when the applet is registered with some data describing the applet.
]=]
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