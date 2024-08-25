local vide = require(script.Parent.Parent.Parent.Parent.Parent.Parent.vide)
local queue = require(script.Parent.Parent.Parent.Parent.Parent.modules.queue)
local remotes = require(script.Parent.Parent.Parent.Parent.Parent.modules.remotes)

local effect = vide.effect
local batch = vide.batch
local cleanup = vide.cleanup

type Context = {
	host: Player | "server",
	vm: number,
	id: number,

	columns: vide.Source<{ { any } }>,
	query: () -> string,

	from: () -> number,
	upto: () -> number,

}

local function generate_random_query_id()
	return math.random(2 ^ 31 - 1)
end

return function(context: Context)

	local query_changed = false
	local page_changed = false

	effect(function()
		if #context.query() > 0 then
			query_changed = true
		end
	end)

	effect(function()
		context.from()
		context.upto()
		page_changed = true
	end)

	local current_query_id = -1
	local query_last_frame = 0
	local update_query_result = queue(remotes.update_query_result)

	local columns = context.columns
	local outgoing = {
		host = context.host,
		to_vm = context.vm
	}

	cleanup(function()
		remotes.disconnect_query:fire(outgoing, current_query_id)
	end)

	return function()

		if query_changed then
			columns({})
			remotes.disconnect_query:fire(outgoing, current_query_id)
			current_query_id = generate_random_query_id()
			remotes.request_query:fire(outgoing, context.id, current_query_id, context.query())
			query_changed = false
		end

		batch(function()
			for incoming, query, frame, column, row, value in update_query_result:iter() do
				if query ~= current_query_id then continue end
				-- if frame < query_last_frame then continue end
				query_last_frame = frame

				if columns()[column] == nil then
					columns()[column] = {}
				end

				columns()[column][row] = value
				columns(columns())
			end
		end)

	end
end