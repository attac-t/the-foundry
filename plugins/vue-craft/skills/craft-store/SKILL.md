---
name: craft-store
description: Pinia setup stores. State, actions, getters. Consume pattern.
---

# Skill: Craft Store

> "Stores hold what components share."

## The Standard

1. **Setup syntax**: `defineStore('name', () => { ... })` — Composition API inside stores.
2. **Sectioned state**: Group related state with comment dividers.
3. **Actions as functions**: Plain functions that mutate state.
4. **Getters as computed**: Derived state with `computed()`.
5. **Consume pattern**: Return value AND clear state in one operation.

## The Anti-Patterns

| Don't                          | Do                             | Why                          |
|--------------------------------|--------------------------------|------------------------------|
| Options API stores             | Setup syntax                   | Consistency with components  |
| Global state for local concerns | Composables                    | Stores are for cross-component |
| Forget to clear after consume  | `consume*()` clears atomically | Prevent stale state bugs     |
| Mix domain logic and caching   | Separate stores                | Single responsibility        |

## Real-World Examples

See [examples.md](examples.md).
