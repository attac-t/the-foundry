---
name: craft-calculation-composable
description: Reactive calculations. toValue unwrapping. Optional formModel sync.
---

# Skill: Craft Calculation Composable

> "Calculations are pure. Reactivity is the glue."

## The Standard

1. **Reactive inputs**: Accept `MaybeRefOrGetter<T>` for flexibility.
2. **toValue unwrapping**: Use `toValue()` inside computed to unwrap refs.
3. **Computed outputs**: All results are `ComputedRef<T>`.
4. **Optional sync**: Use `watchEffect` to sync back to form model when needed.

## The Anti-Patterns

| Don't               | Do                      | Why                                |
|---------------------|-------------------------|------------------------------------|
| `.value` everywhere | `toValue()` in computed | Handles refs, getters, raw values  |
| Mutate in computed  | Return new values       | Purity                             |
| Manual watching     | Computed derivation     | Automatic dependency tracking      |
| Tight form coupling | Optional sync callback  | Reusable                           |

## Real-World Examples

See [examples.md](examples.md).
