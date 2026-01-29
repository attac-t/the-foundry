---
name: decide-guard-vs-exception
description: When to return early vs throw. Control flow clarity.
---

# Skill: Guard vs Exception

> "Guards return. Exceptions signal failure."

## The Decision

**Return early when:**
- Nothing to do is acceptable (empty collection, already processed)
- Caller can continue normally with the return value
- It's a business rule, not an error

**Throw exception when:**
- Caller must handle the failure
- Invalid state that shouldn't exist
- Programmer error (null where null shouldn't be)

## The Heuristic

Ask: *"Can the caller proceed normally with a return value?"*
- **Yes** → Return (Result object, empty collection, early exit)
- **No** → Throw (caller must handle or propagate)

## The Quick Test

| Scenario                    | Answer  | Use       |
|-----------------------------|---------|-----------|
| Empty input, nothing to do? | Ok      | Return    |
| Already processed?          | Ok      | Return    |
| Rate limited, retry later?  | Maybe   | Return Result |
| Missing required data?      | Not ok  | Throw     |
| Unauthorized access?        | Not ok  | Throw     |
| Invalid state (bug)?        | Not ok  | Throw     |

## Real-World Examples

See [examples.md](examples.md).
