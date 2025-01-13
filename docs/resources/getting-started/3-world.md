# World

After we have a way to create our home widget, we need to register applets so
that jabby knows what it can do. Let's start with a basic world applet.

Add the following code to your server and client where the world gets instantiated.

```luau
local jabby = -- your path to jabby here!

-- After you registered your world, add this code.
jabby.register({
    applet = jabby.applets.world,
    name = "world",
    configuration = {
        world = -- put your ecs world here
    }
})
```

By adding this and running it, you should see this in your home widget.

![An image of the same home widget but with a world button, indicated it registered succesfully](/getting-started-2.png)

Clicking it opens the World widget, whichs allows you to view and edit entities.
Further usage should be inferred from the API documentation for now as writing
tutorials is a pain.
