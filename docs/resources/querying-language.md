# jabby's Query Language

Jabby's query syntax is limited, but should be good enough for most use-cases.

## Terms

Queries consist of a list of [terms](#terms), separated by commas. Each term refers to a
value that the entity must have.

### Name

This refers to a named term. Terms in jabby get their name from the applet.

This would display a list of all entities that have a Position __and__ Rotation component.
By default, jabby only supports alphanumeric characters and underscores for the language,
but it's possible to get named terms using characters not part of that by surrounding them
in `"`.

```
Position, Rotation, "jecs.ChildOf"
```


### Ids

You can refer to a term with a specific number id by prefixing it with a `$`.
In jecs, this allows you to refer to a specific entity, which is useful for relationships.

This would display a list of all entities that have a term with id 4.
```
$4
```


### Relationships

Relationships typically consist of the relationship, and the target. They can
be defined by surrounding two terms in `()`. This will create a new term,
the relationship, and become a new term. You are not allowed to use modifiers
or other relationships within a relationship.

This would display a list of all entities with a relationship where the relationship is
ChildOf and the target is entity id 624.

```
(ChildOf, $624)
```

#### Wildcard

Wildcards receive their own character, `*`. They let you query for every entity
with a relationship where only one part matches. This will not display any values.

This would display a list of all entities with a OnCooldown relationship.

```
(OnCooldown, *)
```

## Modifiers

By default, a result must meet the term's condition. You can modify this by using
modifiers, which change the behavior of a term.

### Not

Use the `!` operator to reverse the result of a term. This will exclude any results
that meet the condition.

This would display a list of all entities that have `Enemy` and do not have `Poisoned`.

```
Enemy !Poisoned
```

### Tag

Use the `#` operator to ignore the values of a term, treating it as a tag.
This will not display any data in the view for a specific term.

This would display a list of all entities that have `Enemy` and `Poisoned`, but
not display any data for `Poisoned`.

```
Enemy, #Poisoned
```
