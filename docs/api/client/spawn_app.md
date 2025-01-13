---
layout: doc
aside: right
---

# spawn_app

Spawns a widget provided by the client's apps

<DividePage>

<template #left>

## Arguments

### `app` <Badge type="info" text="App<T>" />

A client application to spawn.

### `config` <Badge type="info" text="T" />

Configuration details for the client.

</template>
<template #right>

```luau
function client.spawn_app<T>(app: App<T>, config: T)
```

</template>

</DividePage>

<DividePage :top="63">
<template #left>

## Return Properties <Badge type="info" text="SystemData"/>

### `destructor` <Badge type="info" text="() -> ()"/>

Destroys the widget created by this call. Does not destroy any widgets created by this widget.

</template>
</DividePage>
