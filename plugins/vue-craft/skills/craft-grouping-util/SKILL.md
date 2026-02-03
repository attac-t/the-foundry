---
name: craft-grouping-util
description: Day/week/month grouping. Functional pipeline.
---

# Skill: Craft Grouping Util

> "Group → Transform → Sort."

## The Standard

1. **Pipeline pattern**: `reduce` → `map` → `sort` chain.
2. **Factory function**: `createDayGroup()` builds consistent group objects.
3. **Totals calculation**: Aggregate within each group.
4. **Sort descending**: Most recent first.

## The Anti-Patterns

| Don't                  | Do                       | Why        |
|------------------------|--------------------------|------------|
| Mutate during grouping | Reduce to new object     | Immutable  |
| Inline group creation  | Factory function         | Consistent |
| Forget edge cases      | Handle invalid dates     | Robust     |
| Sort ascending         | Descending (newest first) | UX         |

## Real-World Examples

See [examples.md](examples.md).
