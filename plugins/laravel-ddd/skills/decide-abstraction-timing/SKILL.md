---
name: decide-abstraction-timing
description: When to abstract vs copy-paste. The rule of three.
---

# Skill: Abstraction Timing

> "Duplication is far cheaper than the wrong abstraction."

## The Decision

**Copy-Paste when:**
- First occurrence (always)
- Second occurrence (usually)
- Contexts differ slightly

**Abstract when:**
- Third occurrence with same pattern
- Change in one requires change in all
- Test coverage becomes repetitive

## The Heuristic

Ask: *"If I change one, must I change all?"*

## The Quick Test

| Ask                             | Answer | Use                  |
|---------------------------------|--------|----------------------|
| First time seeing this pattern? | Yes    | Copy-paste           |
| Second time, same context?      | Yes    | Copy-paste (note it) |
| Third time, identical pattern?  | Yes    | Abstract             |
| Slight variations each time?    | Yes    | Keep separate        |

## Real-World Examples

See [examples.md](examples.md).
