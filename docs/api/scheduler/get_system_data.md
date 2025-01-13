---
layout: doc
aside: right
---

# Scheduler:get_system_data

Obtains information about a given system.

<DividePage>

<template #left>

## Arguments

### `id` <Badge type="info" text="number" />

The system id to obtain information from. This system must be registered,
otherwise an error will be thrown.

</template>
<template #right>

```luau
scheduler:get_system_data(id: number)
```

</template>

</DividePage>

<DividePage :top="63">
<template #left>

## Return Properties <Badge type="info" text="SystemData"/>

### `name` <Badge type="info" text="string"/>

The name of the system that is executed.

### `phase` <Badge type="info" text="string?"/>

The phase the system is executed in by the guest scheduler.

### `paused` <Badge type="info" text="boolean"/>

Indicates if the system is actively running or not. If true, `scheduler:run`
will not run the system.

</template>
<template #right>

```luau
type SystemData = {
    name: string,
    phase: string?,
    paused: boolean
}
```

</template>
</DividePage>
