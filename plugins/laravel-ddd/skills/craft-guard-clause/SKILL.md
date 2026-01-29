---
name: craft-guard-clause
description: Crafting Guard Clauses. Early returns for preconditions.
---

# Skill: Craft Guard Clause

> "Handle the bad cases first. Let the happy path breathe."

## The Standard

1. **Guards at the top**: All precondition checks before any business logic.
2. **One check, one exit**: Each guard handles one condition, then returns or throws.
3. **Flat over nested**: Guards eliminate if/else trees. Main logic lives at outer scope.

## The Anti-Patterns

| ❌ Don't                     | ✅ Do                          | Why                           |
|-----------------------------|-------------------------------|-------------------------------|
| Nested if/else trees        | Guard clauses                 | Readability, maintainability  |
| Check then continue         | Check then exit               | Happy path stays clear        |
| 10+ guards in one method    | Split the method              | Too many guards = too much responsibility |
| Silent return on failure    | Return Result or throw        | Caller needs to know          |

## Real-World Examples

See [examples.md](examples.md).
