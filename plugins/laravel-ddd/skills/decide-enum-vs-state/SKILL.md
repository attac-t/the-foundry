---
name: decide-enum-vs-state
description: When to use enum vs state pattern. Complexity threshold.
---

# Skill: Enum vs State

> "Enums are labels. States are behavior."

## The Decision

**Use Enum when:**
- Simple labels with no behavior
- 1-2 places check the value
- No state-specific logic

**Use State Pattern when:**
- State has behavior (methods, calculations)
- 3+ places check the same state
- Transitions have side effects

## The Heuristic

Ask: *"Does the state DO anything, or just BE something?"*

## The Quick Test

| Ask | Answer | Use |
|-----|--------|-----|
| Do I need methods on the state? | Yes | State Pattern |
| Are there 3+ places with `if ($status === ...)` | Yes | State Pattern |
| Do transitions trigger side effects? | Yes | State Pattern |
| Is it just a label for display? | Yes | Enum |

## Real-World Examples

See [examples.md](examples.md).
