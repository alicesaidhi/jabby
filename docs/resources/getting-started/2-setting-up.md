# Setting up

On the server, make sure you require jabby in a file that runs on start up.
You currently don't have to do anything with it.

On the client, we need to spawn the [home widget](../../api/client/apps.md).
This is necessary so that we can access parts of the applets that we are registering
later on.

Add this code somewhere on the client. It lets you open jabby in a widget somewhere
using F4. Make sure the code is required or ran by something else.

```luau
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local jabby = -- your path to jabby here!

local client = jabby.obtain_client()

local function create_widget(_, state: Enum.UserInputState)
    if state ~= Enum.UserInputState.Begin then return end
    client.spawn_app(client.apps.home, nil)
end

ContextActionService:BindAction("Open Jabby Home", create_widget, false, Enum.KeyCode.F4)
```

You should see this pop up after pressing F4 on your keyboard if you were to
take this example.

![An image of the jabby Home widget](/getting-started-1.png)
