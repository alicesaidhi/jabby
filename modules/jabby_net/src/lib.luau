--[[
jabby_net is a thin networking layer for jabby that allows for applets to send
data to other applets.

]]

local types = require(script.Parent.packages.jabby_types)

export type UniqueSocketRequestTarget = types.Host
export type UniqueInvokeRequestInformation = {
	host: types.Host,
	uuid: number
}


--- A invoke channel is a route for another applet to communicate to this applet and receive a result back
export type AppletInvokeChannel<Send, Receive> = {
	applet: types.JabbyApplet<any>,
	channel_name: string,
	kind: "function",

	--- sends a request to the applet, expecting some answer back
	invoke: (Send) -> (Receive),
	
	--- ran whenever a request is received. unique request information refers to where the request came from.
	--- when you want to return a result, call the receive function
	requested: () -> () -> (UniqueInvokeRequestInformation, (Receive) -> (), Send)
}


--- A event channel is a route for another applet to send a one-way communication to the applet
export type AppletEventChannel<Send> = {
	applet: types.JabbyApplet<any>,
	channel_name: string,
	kind: "event",

	--- fires an event to the applet
	fire: (Send) -> (),
	
	--- ran whenever a request is received. unique request information refers to where the request came from.
	--- when you want to return a result, call the receive function
	requested: () -> () -> ( UniqueInvokeRequestInformation, Send)
}

--- Streaming layers are basically a web socket. ps they send data over an unreliable channel
export type AppletStream<Send, Receive> = {
	applet: types.JabbyApplet<any>,

	stream_id: number,
	target: UniqueSocketRequestTarget,

	send: (Send) -> (),
	receive: () -> () -> (Receive),
}

--- A streaming channel is useful for filtering network traffic 
export type AppletStreamingChannel<Send, Receive, Request> = {
	applet: types.JabbyApplet<any>,
	channel_name: string,
	kind: "stream",
	reliability: "unreliable" | "reliable",

	--- requests a streaming layer to be setup
	request: (Request) -> AppletStream<Send, Receive>,
	
	--- ran whenever a request is received. unique request information refers to where the request came from.
	--- when you want to return a result, call the receive function
	requested: () -> () -> ( UniqueInvokeRequestInformation, Send)

}

--- The network layer is in charge of keeping all the channels and sockets organized
export type AppletNetworkLayer = {
	applet: types.JabbyApplet<any>,
	channels: {
		[string]:
			| AppletInvokeChannel<unknown, unknown>
			| AppletStreamingChannel<unknown, unknown, unknown>
			| AppletEventChannel<unknown>
	},
}

--- A template for a networking layer. This is shared and is used for identification.
export type NetworkLayerTemplate = {
	channels: {
		[string]:
			| AppletInvokeChannel<unknown, unknown>
			| AppletStreamingChannel<unknown, unknown, unknown>
			| AppletEventChannel<unknown>
	}
}

local function ASSERT_UNIQUE_LAYER(layer: AppletNetworkLayer, identifier: string)
	local channel = layer.channels[identifier]

	assert(not channel, `channel "{identifier}" on {layer.applet:unique_name()}`)
end

local function request<Request>(channel: AppletStreamingChannel<unknown, unknown, Request>, request: Request)
	
end

--[=[
Creates a new networking layer on a AppletNetworkLayer
]=]
local function create_applet_stream_event<Send, Receive, Request>(layer: AppletNetworkLayer, identifier: string): AppletStreamingChannel<Send, Receive, Request>
	ASSERT_UNIQUE_LAYER(layer, identifier)

	local channel = {
		applet = layer.applet,
		channel_name = identifier,
		kind = "stream",
		reliability = "unreliable",
	}

	return channel
end

local function create_applet_layer()

end