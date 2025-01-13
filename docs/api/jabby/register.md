---
layout: doc
aside: right
---

# register

Registers a new [applet](./applets/) and broadcasts it to every client.

<DividePage>

<template #left>

## Arguments

### `info` <Badge type="info" text="AppInfo" />

Config for the applet the user is trying to register

</template>
<template #right>

```luau
jabby.register(app: AppInfo)
```

```luau
type AppInfo = {
    name: string,
    applet: Applet<T>,
    configuration: T
}
```

</template>
</DividePage>
