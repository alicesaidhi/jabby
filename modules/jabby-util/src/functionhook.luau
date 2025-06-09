local function i_hook_onto(hook_onto: {[any]: any}, key: string, hooks: {(...any) -> ()})

	local method: any = hook_onto[key]

	assert(typeof(method) == "function", "can only hook onto functions")

	-- create a new wrapper function
	local function run_hook(...)
		for _, hook in hooks do
			hook(...)
		end
		return method(...)
	end

	-- print(debug.info(world[key], "s"))
	hook_onto[key] = run_hook

	local function unhook()
		hook_onto[key] = method
	end
	
	return unhook
end

local hooks = {}

local function find_swap_pop<T>(list: {T}, value: T)
	local idx = table.find(list, value)
	if not idx then return end
	list[idx] = list[#list]
	list[#list] = nil
end

--[[
Hooks a method on the given table, replacing it for it's own. Any calls to this
method will first call the hook, before calling the method.
]]
local function hook_onto(t: any, key: string, hook: (...any) -> ())

	local hash = `{t}:{key}`
	if hooks[hash] == nil then
		local callbacks = {}
		local cleanup = i_hook_onto(t, key, callbacks)
		hooks[hash] = {
			cleanup = cleanup,
			callbacks = callbacks
		}
	end

	local hook_info = hooks[hash]
	local dead = false
	table.insert(hook_info.callbacks, hook)

	local function unhook()
		if dead then return end
		dead = true
		find_swap_pop(hook_info.callbacks, hook)
		
		if hook_info.callbacks[1] == nil then
			hook_info.cleanup()
			hooks[hash] = nil
		end
	end

	return unhook
end

return {
	hook_onto = hook_onto
}