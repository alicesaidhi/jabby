---
layout: doc
aside: right
---

# Scheduler:register_system

Registers a new system

<DividePage>

<template #left>

## Arguments

### `settings` <Badge type="info" text="SystemData" />

The initial data to register the system with.

## Return Values

### `id` <Badge type="info" text="number"/>

The system id unique to the scheduler.

</template>
<template #right>

```luau
type SystemData = {
    name: string,
    phase: string?,
    paused: boolean?
}
```

```luau
local id = scheduler:register_system({
    name = "update_velocity",
    phase = "physics",
    paused = false
})
```

</template>
</DividePage>
