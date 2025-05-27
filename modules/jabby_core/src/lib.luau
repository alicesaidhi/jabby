
local jabby_types = require(script.Parent.Parent.roblox_packages.jabby_types)
local vm_counter = require(script.Parent.vm_counter)
local vm_id = require(script.Parent.vm_id)

export type Host = jabby_types.Host
export type JabbyApplet<T> = jabby_types.JabbyApplet<T>
export type JabbyAppletInterface<T> = jabby_types.JabbyAppletInterface<T>
export type JabbyCore = {
	applet: <T>( applet: JabbyAppletInterface<T>, config: T ) -> ()
}

--- @class jabby_core

local active_applets = {}

--[=[
Registers a new applet with the provided interface internally with jabby.

The applet provided needs to respect the given interface and can take a optional
config to store any extra data that the applet needs to know about.

@within jabby_core
@param applet JabbyAppletInterface<T>
@param config T
@returns JabbyApplet
]=]
local function register_applet<T>(applet: JabbyAppletInterface<T>, config: T)
	local applet_data: JabbyApplet<T> = {
		name = applet.name,
		description = applet.description,
		configuration = config,
		unique_id = vm_counter()
	}

	active_applets[applet_data.unique_id] = applet_data

	applet.registered(applet_data)

	return applet_data
end

--[=[
@within jabby_core
@prop vm_id number

A unique identifier for each vm. This starts counting from 0 and is unique for
each actor.
]=]
return {
	active_applets = active_applets,
	vm_id = vm_id,

	register_applet = register_applet
}