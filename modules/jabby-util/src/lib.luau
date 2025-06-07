
local queue = require(script.Parent.queue)
local result = require(script.Parent.result)
local yield = require(script.Parent.yield)
local functionhook = require(script.Parent.functionhook)

export type Queue<T...> = queue.Queue<T...>
export type Result<Ok, Err = string> = result.Result<Ok, Err>
export type BasicYieldUtil<T...> = yield.BasicYieldUtil<T...>

return {
	queue = queue,
	yield = yield,
	result = result,

	functionhook = functionhook
}