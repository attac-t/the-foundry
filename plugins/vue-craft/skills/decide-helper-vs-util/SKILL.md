---
name: decide-helper-vs-util
description: Reactive needs? Helper. Pure logic? Util.
---

# Decide: Helper vs Util

> "Helpers react. Utils compute."

## The Heuristic

| Helper Composable         | Utility Function          |
|---------------------------|---------------------------|
| Returns computed values   | Returns static values     |
| Domain-specific           | Reusable across domains   |
| Named `use{Entity}Helper` | Named `{action}{Thing}`   |
| Lives in domain           | Lives in `utils/`         |

## Quick Test

**Ask:** "Does this return `computed()` or `ref()`?"

- **Yes** → Helper composable
- **No** → Utility function

## The Anti-Pattern

**Reactive util**: A function in `utils/` that imports from Vue. Put it in composables.

## Real-World Examples

See [examples.md](examples.md).
