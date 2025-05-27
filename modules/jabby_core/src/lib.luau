local jabby_types = require(script.Parent.Parent.roblox_packages.jabby_types)
local host = require(script.Parent.host)
local vm_counter = require(script.Parent.vm_counter)
local vm_id = require(script.Parent.vm_id)

export type Host = jabby_types.Host
export type JabbyApplet<T> = jabby_types.JabbyApplet<T>
export type JabbyAppletInterface<T> = jabby_types.JabbyAppletInterface<T>
export type JabbyCore = {
	applet: <T>( applet: JabbyAppletInterface<T>, config: T ) -> ()
}

local active_applets = {}

local function get_applet_hash(host: Host, id: number)
	return `{host}:{id}`
end

local function get_unique_name<T>(applet: JabbyApplet<T>)
	return `{applet.name}:{applet.unique_id}`
end

--[=[
Registers a new applet with the provided interface internally inside the jabby core.
]=]
local function register_applet<T>(applet: JabbyAppletInterface<T>, config: T)
	local applet_data = {
		name = applet.name,
		description = applet.description,
		configuration = config,
		unique_id = vm_counter()
	} :: JabbyApplet<T>

	active_applets[get_applet_hash(host, applet_data.unique_id)] = applet_data

	applet.registered(applet_data)

	return applet_data
end

return {
	active_applets = active_applets,
	vm_id = vm_id,

	register_applet = register_applet
}