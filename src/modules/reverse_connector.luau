--!nocheck
local types = require(script.Parent.types)

local function reverse(connector: types.IncomingConnector): types.OutgoingConnector
	return {
		namespace = connector.namespace,
		to_vm = connector.from_vm,
	}
end

return reverse