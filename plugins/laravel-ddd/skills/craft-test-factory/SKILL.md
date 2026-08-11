---
name: craft-test-factory
description: Crafting Test Factories. Beyond Laravel defaults.
---

# Skill: Craft Test Factory

> "The power of a factory is not the complexity of the code, but rather one or two patterns properly applied."

## The Standard

1. **Static `new()` Constructor**: Entry point. Returns fresh instance.
2. **Immutability via Clone**: State methods return cloned instance, never mutate.
3. **Auto-Increment Uniques**: Static counter for unique fields like invoice numbers.
4. **Beyond Models**: Create DTOs, events, requests—anything tests need.

## The Anti-Patterns

| ❌ Don't             | ✅ Do                       | Why                       |
|----------------------|-----------------------------|---------------------------|
| Mutable state        | Clone on every modifier     | Prevents test pollution   |
| Random unique values | Static incrementing counter | Deterministic, debuggable |
| Laravel factory only | Custom factories too        | DTOs need factories too   |
| Inline test setup    | Named factory states        | Self-documenting tests    |

## Real-World Examples

See [examples.md](examples.md).
