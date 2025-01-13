---
layout: doc
aside: right
---

# applets.world

<script setup>
  import {DividePage} from 'vitepress-theme-api';
</script>

The scheduler applet gains insight into a user's scheduler via the [Scheduler](../scheduler/)
object that jabby provides, which serves as an interface to the user-built
scheduler.

<DividePage :top="63">
<template #left>

## scheduler

The scheduler displayed in the applet.

</template>
<template #right>

```luau
type SchedulerApplet = {
    scheduler: jabby.Scheduler
}
```

</template>
</DividePage>
