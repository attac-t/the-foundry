---
name: craft-filter-composable
description: Type-switched query generation. Exhaustive switch. Computed output.
---

# Skill: Craft Filter Composable

> "The type determines the query."

## The Standard

1. **Type switch**: Use `switch` on model type to build query.
2. **Exhaustive cases**: Handle all possible types explicitly.
3. **Base query**: Start with common filters, add type-specific ones.
4. **Computed output**: Return reactive query object.

## The Anti-Patterns

| Don't              | Do               | Why                 |
|--------------------|------------------|---------------------|
| If-else chain      | Switch statement | Cleaner, exhaustive |
| Build query inline | Helper function  | Testable            |
| Ignore types       | Handle all cases | Type safety         |
| Manual reactivity  | Computed         | Automatic updates   |

## Real-World Examples

See [examples.md](examples.md).
