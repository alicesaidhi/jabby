
local queue = require("./queue")
local result = require("./result")

export type Queue<T...> = queue.Queue<T...>
export type Result<Ok, Err = string> = result.Result<Ok, Err>

return {
	queue = queue,
	result = result
}