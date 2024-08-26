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

jabby can be used with actors and is able to be used to inspect other players.
`table.insert` schedulers / worlds to `jabby.public` and set `jabby.public.updated` to true. There will probably be a better api for this later.

When inserting a jecs world to the public table, make sure it's stored like so:
```lua
jabby.public[1] = {
	 -- identifier jabby needs to know its a world
	class_name: "World",
	-- the name of how it will be displayed
	name: string,
	-- your actual world
	world: jecs.World,
	-- a entity that is used to store the name of any components you want to be
	-- able to query.
	debug: jecs.Entity<string>,
	-- a hashmap of entities that can be selected by the debugger's pick tool
	entities: {[Instance]: jecs.Entity<any>}
}
```

You can directly insert a scheduler into jabby.
