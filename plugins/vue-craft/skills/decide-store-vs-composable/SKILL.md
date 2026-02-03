---
name: decide-store-vs-composable
description: Store for cross-component. Composable for local.
---

# Decide: Store vs Composable

> "Does another component need this state?"

## The Heuristic

| Use Store When                 | Use Composable When     |
|--------------------------------|-------------------------|
| State shared across components | State local to one tree |
| Persist across navigation      | Reset on unmount is OK  |
| Need consume pattern           | Simple reactive logic   |
| Cross-page data transfer       | Same-page logic         |

## Quick Test

**Ask:** "Would unmounting this component lose important state?"

- **Yes** → Store (persist beyond component lifecycle)
- **No** → Composable (lives and dies with component)

## The Anti-Pattern

**Over-storing**: Putting component-local state in Pinia. Adds complexity without benefit.

## Real-World Examples

See [examples.md](examples.md).
