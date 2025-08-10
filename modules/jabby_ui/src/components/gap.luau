local container = require(script.Parent.container)

return function(size: number)

	return container {
		w = size, h = size
	}
end