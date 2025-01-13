---
layout: doc
aside: right
---

# Scheduler:set_system_data

Patches data to a system

<DividePage>

<template #left>

## Arguments

### `id` <Badge type="info" text="number"/>

The system id to obtain information from. This system must be registered,
otherwise an error will be thrown.

### `settings` <Badge type="info" text="SystemData"/>

A dictionary of settings that will overwrite the existing settings. This is
patched on top of the system's existing data where the provided values replace
the old values.

</template>
<template #right>

```luau
scheduler:set_system_data(
    id: number,
    settings: SystemData
)
```

```luau
type SystemData = {
    name: string?,
    phase: number?,
    paused: boolean?
}
```

</template>

</DividePage>
