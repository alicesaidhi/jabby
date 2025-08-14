local convertscale = require(script.Parent.convertscale)
local functionhook = require(script.Parent.functionhook)
local queue = require(script.Parent.queue)
local result = require(script.Parent.result)
local yield = require(script.Parent.yield)

export type Queue<T...> = queue.Queue<T...>
export type Result<Ok, Err = string> = result.Result<Ok, Err>
export type BasicYieldUtil<T...> = yield.BasicYieldUtil<T...>

return {
	convert_scale = convertscale,

	queue = queue,
	yield = yield,
	result = result,

	merge = function<T>(a: { T }, b: { T }): { T }
		local c = table.clone(a)
		table.move(b, 1, #b, #a + 1, c)
		return c
	end,

	functionhook = functionhook,
}
