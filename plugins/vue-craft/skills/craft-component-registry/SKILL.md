---
name: craft-component-registry
description: Dynamic component dispatch. Type-to-component map.
---

# Skill: Craft Component Registry

> "One component. Many faces."

## The Standard

1. **Type config map**: `Record<TypeKey, { component, propsBuilder }>`.
2. **Computed dispatch**: `component` and `componentProps` derived from type.
3. **Lazy components**: Each entry uses `defineAsyncComponent`.
4. **Props builder**: Function that constructs props for each type.

## The Anti-Patterns

| Don't                     | Do                       | Why           |
|---------------------------|--------------------------|---------------|
| Giant v-if chain          | Registry pattern         | Maintainable  |
| Inline prop construction  | `propsBuilder` function  | Testable      |
| Eager load all variants   | Lazy load each           | Bundle size   |
| Switch on type everywhere | Centralize config        | Single source |

## Real-World Examples

See [examples.md](examples.md).
