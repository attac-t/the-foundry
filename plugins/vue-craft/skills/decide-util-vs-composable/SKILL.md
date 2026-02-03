---
name: decide-util-vs-composable
description: Pure vs reactive. Side effects decide.
---

# Decide: Util vs Composable

> "Does it use Vue reactivity?"

## The Heuristic

| Use Util When                | Use Composable When               |
|------------------------------|-----------------------------------|
| Pure function                | Uses `ref`, `computed`, `watch`   |
| Input → Output               | Returns reactive state            |
| No Vue imports               | Needs Vue lifecycle               |
| Same result for same input   | Result changes over time          |

## Quick Test

**Ask:** "Can this function run in a plain Node.js script?"

- **Yes** → Util (pure, no Vue)
- **No** → Composable (needs Vue runtime)

## The Anti-Pattern

**Reactive util**: Using `ref` in what should be pure logic. Adds complexity, loses testability.

## Real-World Examples

See [examples.md](examples.md).
