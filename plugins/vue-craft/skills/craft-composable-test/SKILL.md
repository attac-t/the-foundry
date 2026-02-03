---
name: craft-composable-test
description: Composable testing. Helper factories. Reactive assertions.
---

# Skill: Craft Composable Test

> "Test behavior, not implementation."

## The Standard

1. **Helper factories**: `createUser()`, `createMoney()` — consistent test data.
2. **Reactive assertions**: Mutate ref, assert computed updates.
3. **Tier-based structure**: One test per behavior tier/case.
4. **Edge cases explicit**: Null entity, null total, boundary values.

## The Anti-Patterns

| Don't                    | Do                     | Why                   |
|--------------------------|------------------------|-----------------------|
| Inline test data         | Helper factories       | Consistent, readable  |
| Assert once              | Mutate and re-assert   | Test reactivity       |
| Skip null cases          | Explicit null tests    | Edge case coverage    |
| Describe implementation  | Describe behavior      | Maintainable          |

## Real-World Examples

See [examples.md](examples.md).
