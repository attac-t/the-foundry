---
name: craft-util
description: Pure utility functions. Named params. Test colocation.
---

# Skill: Craft Util

> "Pure functions. No surprises."

## The Standard

1. **Named params**: `{ param1, param2 }` — never positional arguments.
2. **Test colocation**: `__tests__/` directory next to implementation.
3. **Types separation**: `{utilName}.types.ts` for input/output types.
4. **Export helpers**: Internal functions exported for testing.

## The Anti-Patterns

| Don't           | Do                      | Why              |
|-----------------|-------------------------|------------------|
| Positional args | Named params object     | Self-documenting |
| Side effects    | Return new values       | Predictable      |
| Tests elsewhere | Colocated `__tests__/`  | Discoverability  |
| Hide internals  | Export for testing      | Verifiable       |

## Real-World Examples

See [examples.md](examples.md).
