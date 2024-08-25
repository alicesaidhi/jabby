local RunService = game:GetService("RunService")

local vide = require(script.Parent.Parent.Parent.Parent.vide)
local loop = require(script.Parent.Parent.Parent.modules.loop)
local widget = require(script.widget)

local source = vide.source
local cleanup = vide.cleanup

local overview_query = {
	class_name = "app" :: "app",
	name = "Query"
}

type props = {
	host: Player | "server",
	vm: number,
	id: number
}

function overview_query.mount(props: props, destroy: () -> ())

	local enable_pick = source(false)
	local entity_hovering_over = source()
	local hovering_over = source()

	local validate_query = source("")
	local ok = source(false)
	local msg = source("")

	local query = source("")
	local columns = source({})
	local from = source(1)
	local upto = source(25)
	local total_entities = source(0)

	-- check if the query and columns are properly
	local app_loop = loop (
		"app-client-registry",
		{
			host = props.host,
			vm = props.vm,
			id = props.id,

			enable_pick = enable_pick,
			entity_hovering_over = entity_hovering_over,
			hovering_over = hovering_over,

			columns = columns,
			query = query,

			total_entities = total_entities,

			from = from,
			upto = upto,

			validate_query = validate_query,
			ok = ok,
			msg = msg
		},

		{i = 1},
		script.systems.validate_query,
		script.systems.obtain_query_data,
		script.systems.send_workspace_entity,
		script.systems.highlight_workspace_entity
	)

	cleanup(
		RunService.Heartbeat:Connect(app_loop)
	)

	return widget {
		host = props.host,
		vm = props.vm,
		id = props.id,

		validate_query = validate_query,

		update_system_query = query,
		current_query = query,
		total_rows_per_page = source(25),
		set_rows_per_page = source(25),

		from = from,
		upto = upto,
		total_entities = total_entities,

		enable_pick = enable_pick,
		entity_hovering_over = entity_hovering_over,
		hovering_over = hovering_over,

		ok = ok,
		msg = msg,

		columns = columns,
		
		destroy = destroy
	}

end

return overview_query