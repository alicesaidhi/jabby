local result = require(script.Parent.result)

export type BasicYieldUtil<T...> = {
	await: (BasicYieldUtil<T...>) -> T...,
	after: (BasicYieldUtil<T...>, fn: (T...) -> ()) -> BasicYieldUtil<T...>,
	thread: thread,
}

local function create<T...>(fn: () -> T...): BasicYieldUtil<T...>
	local pending_callbacks = {}
	local values

	local function await(): T...
		if values then return unpack(values) end

		local thread = coroutine.running()
		local still_waiting = true
		local closure = function()
			if still_waiting == false then return end
			coroutine.resume(thread)
		end

		table.insert(pending_callbacks, closure)

		coroutine.yield()
		still_waiting = false

		return values and unpack(values)
	end

	local function after(callback: (T...) -> ())
		table.insert(pending_callbacks, callback)
	end

	local self = {}

	function self:await() return await() end

	function self:after(fn: (T...) -> ())
		after(fn)
		return self
	end

	self.thread = task.spawn(function()
		values = { fn() }
		for _, callback in pending_callbacks do
			local r = result.safe(callback, unpack(values))
			if not r.ok then warn(r.why) end
		end
	end)

	return self
end

return create
