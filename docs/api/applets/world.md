---
layout: doc
aside: right
---

# applets.world

<script setup>
  import {DividePage} from 'vitepress-theme-api';
</script>

The world applet allows for querying, editing and selecting entities in the DataModel or ECS.

<DividePage :top="63">
<template #left>

## world

The world that will be queried and used by the application.

## get_entity_from_part

Function used to obtain the Entity when given a Part from Workspace.
When used with the highlighting functionality of jabby, users will be able to
select and highlight an Instance with their associated model in Workspace.

## entities <Badge type="warning" text="Deprecated"/>

A deprecated way for jabby to obtain the Instance a user is trying to select,
by directly mapping each Instance to an entity.

</template>
<template #right>

```luau
type WorldApplet = {
    world: jecs.World,
    get_entity_from_part: ((part: BasePart) -> (jecs.Entity<any>, PVInstance?))?,
    entities: {[Instance]: jecs.Entity<any>}?,
}
```

```luau
local function get_entity_from_part(part: BasePart): (jecs.Entity<any>, PVInstance)?
    for id, model in world:query(jecs.Model):iter() do
        if not part:IsDescendantOf(model) then continue end
        return id, model
    end
end
```

</template>
</DividePage>
