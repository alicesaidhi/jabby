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

	local validate_query = source("")
	local ok = source(false)
	local msg = source("")

	local query = source("")
	local columns = source({})
	local from = source(1)
	local upto = source(25)

	-- check if the query and columns are properly
	local app_loop = loop (
		"app-client-registry",
		{
			host = props.host,
			vm = props.vm,
			id = props.id,

			columns = columns,
			query = query,

			from = from,
			upto = upto,

			validate_query = validate_query,
			ok = ok,
			msg = msg
		},

		{i = 1},
		script.systems.validate_query,
		script.systems.obtain_query_data
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
		total_entities = source(0),
		total_rows_per_page = source(25),
		set_rows_per_page = source(25),

		ok = ok,
		msg = msg,

		columns = columns,
		
		destroy = destroy
	}

end

return overview_query