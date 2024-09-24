# jabby

jabby is a debugger for [jecs](https://github.com/ukendio/jecs) based off [gorp](https://github.com/aloroid/gorp)

It's still in the early stages of development and is very experimental.

> [!NOTE]
> jabby is compatible with [jecs 0.2.9](https://github.com/Ukendio/jecs/releases/tag/v0.2.9) and up.
> Do not install jecs 0.3.0-rc.1, it is not compatible (for some reason, it's older than 0.2.9??)

> [!NOTE]
> jabby requires vide with the recursive queue fix patch (git commit [fbe2f01](https://github.com/centau/vide/commit/fbe2f01bb99e7f7744d5039f36c494044f044883))

While jabby is currently only compatible with jecs, the intent is to be able to use this as a alternative debugger for Matter and ECR in the future as well.

## How to get it working

jabby shouldn't be too intrusive to integrate into any existing or new ecs setups, but there are some notes to be made.
The current API is very experimental, and not exactly meant for developer use.
I will probably continue supporting this API in the future, until I have came up with a proper scheduler api.

jabby exposes a `public` field which is where you add your Worlds and
Schedulers to that you want to be exposed to the client. After adding a object
to the public field, you must set `public.updated` to `true` so that jabby knows
to broadcast that a new world and scheduler is added.

### World

When adding a world to jabby, they're expected in the following format:

```luau
type world_data = {
	--- when it reads this, it recognizes the data as a World. required
	class_name: "World",
	--- this is the name that will be displayed in the client
	--- recommendation is to keep it descriptive
	name: string,
	--- the actual jecs world that jabby will read from
	world: jecs.World,
	--- a debug component that jabby uses to get all components and their names.
	debug: jecs.Entity<string>,

	-- the following is optional starting from jabby 0.1.1
	--- associates a entity with a instance. jabby uses this to find the correct
	--- entity associated with the given part. this will be removed in 0.2.0
	--- optional
	entities: {[Instance]: jecs.Entity<any>},
	--- this function is user-provided. when provided, jabby will ignore the entities
	--- field and instead call this function to get the entity. optionally, a instance
	--- can be provided which will be used as a highlight for the entity
	--- optional
	get_entity_from_part: (part: BasePart) -> (jecs.Entity<any>?, Instance?)
}
```

example code:

```lua
local world = jecs.World.new()

local debug = world:entity()

table.insert(
	jabby.public,
	{
		class_name = "World",
		name = "jecs world",
		world = world,
		debug = debug,

		entities = {}
	}
)
jabby.public.updated = true
```

### Scheduler

jabby exposes a scheduler object which is used to report necessary scheduler data to jorp.
You'll need to instantiate your own scheduler and add it to the public table for jabby to see it.

Adding it to the public table is as simple as just using `table.insert` on it.
It's recommended to write your own scheduler, and have it wrap around jabby's scheduler. jabby's scheduler is only meant for reporting data and debugging.

Registering a system can be performed using `scheduler:register_system(settings?)`
settings can be provided to the system. Current relevant settings are `name` and `paused`.

jabby exposes a `scheduler:run()` function to start running a system.

This can be as simple as `scheduler:run(systemId, system, world, delta_time)`, where any arguments after the system will be used as arguments to the system callback.

Note that `scheduler:run` does not check for yielding or pcalls. This should be handled from the user side.

example code

```lua

local scheduler = jabby.scheduler.create("example scheduler")

local system_a = scheduler:register_system {name = "a"}
local system_b = scheduler:register_system {name = "a"}
local system_c = scheduler:register_system {name = "a"}

RunService.Heartbeat:Connect(function(dt)

	scheduler:run(system_a, systems.A, dt)
	scheduler:run(system_b, systems.B, dt)
	scheduler:run(system_c, systems.C, dt)
	
end)

table.insert(jabby.public, scheduler)
jabby.public.updated = true

```

### Running in-game

jabby does not have any significant overhead if you aren't using it, so it's fine
to leave it running in production. If you want to use jabby outside Studio, you are required to set a function which jabby can use to figure out which players are allowed to use jabby in-game.

You can overwrite the function using `jabby.set_check_function`; By default, this checks if you are currently running in Roblox Studio, and allows usage of the debugger while in Studio.

It's recommended to overwrite this to a function that allows the developer to use jabby while in-game. Note that this needs to be set on **every actor on both client and server**, otherwise it won't work. You should set this before spawning a jabby widget.

### Spawning a widget

Jabby exposes `obtain_client`, which should be called in a script without a actor, unless you know what you are doing.
Running `obtain_client` on different actors should not be allowed.

To spawn a widget, just run `client.spawn_app(client.apps.home)`, which will
create a new application where you can select the world / scheduler to debug.
