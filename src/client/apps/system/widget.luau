local pebble = require(script.Parent.Parent.Parent.Parent.Parent.pebble)
local vide = require(script.Parent.Parent.Parent.Parent.Parent.vide)
local types = require(script.Parent.Parent.Parent.Parent.modules.types)
local watch_tracker = require(script.Parent.watch_tracker)

local create = vide.create
local source = vide.source

type props = {
	host: "server" | Player,
	vm: number,

	scheduler: number,
	system: number,
	name: string,

	per_frame_data: () -> {[number]: number},
	changes: () -> types.WatchLoggedChanges,

	destroy: () -> ()
}

return function(props: props)

	return pebble.widget {
		title = `system - {props.name}`,
		subtitle = `host: {props.host} vm: {props.vm} scheduler: {props.scheduler} system: {props.system}`,
		bind_to_close = props.destroy,
		size = Vector2.new(350, 400),
		min_size = Vector2.new(300, 300),

		watch_tracker(props)
	}

end