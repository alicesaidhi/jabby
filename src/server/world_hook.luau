
local jecs = require(script.Parent.Parent.Parent.jecs)
local world = jecs.World.new()

local function i_hook_onto(key: string, hooks: {(...any) -> ()})

	local method: any = world[key]

	assert(typeof(method) == "function", "can only hook onto functions")

	-- create a new wrapper function
	local function run_hook(...)
		for _, hook in hooks do
			hook(...)
		end
		return method(...)
	end

	-- print(debug.info(world[key], "s"))
	world.__index[key] = run_hook

	local function unhook()
		world.__index[key] = method
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

local function hook_onto(key: string, hook: (...any) -> ())

	if hooks[key] == nil then
		local callbacks = {}
		local cleanup = i_hook_onto(key, callbacks)
		hooks[key] = {
			cleanup = cleanup,
			callbacks = callbacks
		}
	end

	local hook_info = hooks[key]
	local dead = false
	table.insert(hook_info.callbacks, hook)

	local function unhook()
		if dead then return end
		dead = true
		find_swap_pop(hook_info.callbacks, hook)
		
		if hook_info.callbacks[1] == nil then
			hook_info.cleanup()
			hooks[key] = nil
		end
	end

	return unhook
end

return {
	hook_onto = hook_onto
}