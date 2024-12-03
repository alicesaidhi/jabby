local types = require(script.Parent.Parent.modules.types)
local world_hook = require(script.Parent.world_hook)

local NIL = newproxy()

type ChangeTypes = "remove" | "clear" | "delete" | "add" | "set" | "entity" | "component"
type Changes = types.WatchLoggedChanges

export type SystemWatch = {
	--- enables Lua Object Notation.
	--- incurs a significant performance penalty.
	enable_lon: boolean,
	--- the current frame to process
	frame: number,

	frames: {[number]: Changes}
}

local function create_changes()
	return {
		types = {},
		entities = {},
		component = {},
		values = {},
		worlds = {}
	}
end

local function step_watch(watch: SystemWatch)
	watch.frame += 1
	watch.frames[watch.frame] = create_changes()
end

local function track_watch(watch: SystemWatch)

	local hooks = {

		world_hook.hook_onto("create", function(self, id, component)
			local frame = watch.frames[watch.frame]
			
			table.insert(frame.types, "create")
			table.insert(frame.entities, id)
			table.insert(frame.component, NIL)
			table.insert(frame.values, NIL)
			table.insert(frame.worlds, self)
		end),
	
		world_hook.hook_onto("destroy", function(self, id)
			local frame = watch.frames[watch.frame]
			
			table.insert(frame.types, "delete")
			table.insert(frame.entities, id)
			table.insert(frame.component, NIL)
			table.insert(frame.values, NIL)
			table.insert(frame.worlds, self)
		end),
	
		world_hook.hook_onto("add", function(self, id, ...)
			local frame = watch.frames[watch.frame]

			for i = 1, select("#", ...) do
				local ctype = select(i, ...)
				if self:has(id, ctype) then continue end
				table.insert(frame.types, "add")
				table.insert(frame.entities, id)
				table.insert(frame.component, ctype)
				table.insert(frame.values, NIL)
				table.insert(frame.worlds, self)
			end
		end),

		world_hook.hook_onto("set", function(self, entity, component, value)
			local frame = watch.frames[watch.frame]
			
			table.insert(frame.types, "set")
			table.insert(frame.entities, entity)
			table.insert(frame.component, component)
			table.insert(frame.values, if value == nil then NIL else value)
			table.insert(frame.worlds, self)
		end),

		world_hook.hook_onto("patch", function(self, entity, component, fn)
			local frame = watch.frames[watch.frame]
			
			table.insert(frame.types, "patch")
			table.insert(frame.entities, entity)
			table.insert(frame.component, component)
			table.insert(frame.values, NIL)
			table.insert(frame.worlds, self)
		end),

		world_hook.hook_onto("remove", function(self, id, component)
			local frame = watch.frames[watch.frame]
			
			table.insert(frame.types, "remove")
			table.insert(frame.entities, id)
			table.insert(frame.component, component)
			table.insert(frame.values, NIL)
			table.insert(frame.worlds, self)
		end),
	
		world_hook.hook_onto("clear", function(self, ...)
			local frame = watch.frames[watch.frame]
			
			for i = 1, select("#", ...) do
				local ctype = select(i, ...)
				table.insert(frame.types, "clear")
				table.insert(frame.entities, NIL)
				table.insert(frame.component, ctype)
				table.insert(frame.values, NIL)
				table.insert(frame.worlds, self)
			end
		end),
		
	}
	
	--- stops all hooks
	local function stop_hook()
		for _, destroy in hooks do
			destroy()
		end
	end

	return stop_hook
end

local function create_watch()
	local watch: SystemWatch = {
		enable_lon = false,

		frame = 0,
		frames = {}
	}

	return watch
end

return {

	create_watch = create_watch,
	track_watch = track_watch,
	step_watch = step_watch,

	NIL = NIL

}