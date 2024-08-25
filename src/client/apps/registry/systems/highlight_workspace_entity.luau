local queue = require(script.Parent.Parent.Parent.Parent.Parent.modules.queue)
local remotes = require(script.Parent.Parent.Parent.Parent.Parent.modules.remotes)
local types = require(script.Parent.Parent.Parent.Parent.Parent.modules.types)

type Context = {
	host: Player | "server",
	vm: number,
	id: number,

	enable_pick: () -> boolean,
	entity_hovering_over: (string) -> (),
	hovering_over: (BasePart) -> ()

}

return function(context: Context)

	local send_mouse_entity = queue(remotes.send_mouse_entity)

	return function()

		for incoming, id, to_highlight, components in send_mouse_entity:iter() do
			if incoming.host ~= context.host then continue end
			if incoming.from_vm ~= context.vm then continue end
			if id ~= context.id then continue end

			context.hovering_over(to_highlight)
			context.entity_hovering_over(components)
		end

	end
	
end