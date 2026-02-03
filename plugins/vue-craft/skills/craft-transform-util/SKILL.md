---
name: craft-transform-util
description: Data transformation utilities. Options object. Pure functions.
---

# Skill: Craft Transform Util

> "Transform without mutating."

## The Standard

1. **Options object**: Configuration in second parameter.
2. **Sensible defaults**: Work without options.
3. **Export internals**: Individual helpers for testing.
4. **Pure transforms**: Input → Output. No side effects.

## The Anti-Patterns

| Don't           | Do                 | Why         |
|-----------------|--------------------|-------------|
| Mutate input    | Spread and modify  | Predictable |
| Boolean flags   | Options object     | Extensible  |
| Hide helpers    | Export all         | Testable    |
| Hardcode values | Defaults + options | Flexible    |

## Real-World Examples

See [examples.md](examples.md).
