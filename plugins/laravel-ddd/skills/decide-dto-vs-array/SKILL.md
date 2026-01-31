---
name: decide-dto-vs-array
description: When to use DTO vs array. Type safety threshold.
---

# Skill: DTO vs Array

> "Arrays are bags of anything. DTOs are contracts."

## The Decision

**Use Array when:**
- Quick prototyping / exploration
- Single-use, local scope
- Framework requires it (config, etc.)

**Use DTO when:**
- Data crosses boundaries (controller → action)
- Same structure appears 2+ times
- Validation needed
- IDE autocomplete matters

## The Heuristic

Ask: *"Will another developer need to know what's in this?"*

## The Quick Test

| Ask | Answer | Use |
|-----|--------|-----|
| Does it cross a class boundary? | Yes | DTO |
| Is it reused elsewhere? | Yes | DTO |
| Does it need validation? | Yes | DTO |
| Is it a quick local variable? | Yes | Array |

## Real-World Examples

See [examples.md](examples.md).
