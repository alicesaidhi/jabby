local types = require(script.Parent.types)

local function reverse(connector: types.connector): types.connector
	return {
		namespace = if connector.player then "client" else "server",
		to = connector.from :: number,
		player = connector.player,
	}
end

return reverse