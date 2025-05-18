local HttpService = game:GetService("HttpService")

local host = require(script.Parent.host)
local jabby_types = require(script.Parent.packages.jabby_types)
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

local function connect_to_applet(who: Host, id: number)
	local applet = active_applets[get_applet_hash(who, id)]

	-- it's on this vm, so we can connect to it directly
	if applet then
		
	-- we are connecting to the server, so we can connect to it directly.
	elseif who == "server" and host ~= "server" then
		
	-- we are connecting to another client, as a client
	elseif who ~= "server" and host ~= who then

	else
		error("unhandled case")
	end
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

	return applet.registered(applet_data)
end

--[=[
Attempts to connect to an incoming applet through the usage of a remote. This will be called from the request_connect remote.

]=]
local function incoming_connection_to_applet(host: Host, id: number)
	local applet = active_applets[get_applet_hash(host, id)]

	if not applet then return end

	
end

return {
	active_applets = active_applets,
	vm_id = vm_id,

	register_applet = register_applet
}