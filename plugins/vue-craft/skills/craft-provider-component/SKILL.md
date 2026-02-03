---
name: craft-provider-component
description: Renderless context provider. Slot-only template.
---

# Skill: Craft Provider Component

> "Provide without rendering."

## The Standard

1. **Slot-only template**: `<template><slot /></template>` — no DOM output.
2. **Injection keys colocated**: Keys in `.types.ts` next to provider.
3. **Symbol-based keys**: `InjectionKey<T>` with `Symbol()` for type safety.
4. **Provider composable**: Setup provides, children inject.

## The Anti-Patterns

| Don't                   | Do                       | Why              |
|-------------------------|--------------------------|------------------|
| String injection keys   | Symbol + InjectionKey    | Type safety      |
| Keys scattered in utils | Colocate with provider   | Discoverability  |
| Render wrapper divs     | Slot only                | No DOM pollution |
| Manual provide/inject   | Provider composable      | Reusability      |

## Real-World Examples

See [examples.md](examples.md).
