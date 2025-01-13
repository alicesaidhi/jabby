---
layout: doc
aside: right
---

# set_check_function

Determines if a player is allowed to use jabby.

> [!WARNING]
> It's not recommended to give this out to players you don't trust, as
> returning true means you allow them to gain insight into how your game works,
> pause systems, create watches, edit entities and more!

<DividePage>

<template #left>

## Arguments

### `callback` <Badge type="info" text="(Player) -> boolean" />

The callback that will be called whenever a player attempts to run jabby.

</template>
<template #right>

```luau
jabby.set_check_function(callback: (Player) -> boolean)
```

> [!NOTE]
> This needs to be called on every single VM. This means that you have to run
> this on both the server, the client, and every actor. This will be addressed
> in a later version for a more regular permission system.

</template>
</DividePage>

## Yielding

A common pattern is to give members of a certain group role access to jabby.
As Roblox requires a yielding call to obtain information about the users role
in a group, it's instead recommended to return false by default, and then return
true if the user is later determined to be in the group. In order to make sure the
player has access to jabby's values, you should call `jabby.broadcast` after
calling this function.
