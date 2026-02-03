---
name: decide-validation-location
description: UI catches typos. API enforces invariants.
---

# Decide: Validation Location

> "Both. For different reasons."

## The Heuristic

| UI Validation      | API Validation       |
|--------------------|----------------------|
| Immediate feedback | Authoritative        |
| Guides user        | Enforces invariants  |
| Catches typos      | Catches logic errors |
| Can be lenient     | Must be strict       |
| Zod schema         | Laravel Form Request |

## Quick Test

**Ask:** "What happens if this validation is bypassed?"

- **User annoyance** → UI validation (nice to have)
- **Data corruption** → API validation (required)

## The Standard

**Both layers.** UI for UX. API for safety.

## Real-World Examples

See [examples.md](examples.md).
