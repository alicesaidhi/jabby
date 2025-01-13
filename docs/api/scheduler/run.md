---
layout: doc
aside: right
---

# Scheduler:run

Runs the given function and profiles it with the given system.

<DividePage>

<template #left>

## Arguments

### `id` <Badge type="info" text="number"/>

The system id associated with the function. This system must be registered,
otherwise an error will be thrown.

### `system` <Badge type="info" text="(T...) -> ()"/>

A dictionary of settings that will overwrite the existing settings. This is
automatically patched, and new values will replace old values.

### `...` <Badge type="info" text="T..."/>

Any arguments passed will be passed to the system.

</template>
<template #right>

```luau
scheduler:run(
    id: number,
    system: (T...) -> (),
    ...: T...
)
```

</template>

</DividePage>
