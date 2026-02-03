---
name: decide-composable-extraction
description: When to extract a composable. Rule of three.
---

# Decide: Composable Extraction

> "Extract when the pattern repeats."

## The Heuristic

| Extract When                 | Keep Inline When              |
|------------------------------|-------------------------------|
| Used in 3+ places            | Used once                     |
| Logic is complex (5+ refs)   | Simple 1-2 ref setup          |
| Testable in isolation        | Tightly coupled to component  |
| Reusable across domains      | Component-specific            |

## Quick Test

**Ask:** "Would another component need this exact reactive logic?"

- **Yes** → Extract to `use{Feature}/`
- **No** → Keep in component

## The Anti-Pattern

**Premature extraction**: Creating composables for single-use logic adds indirection without benefit.

## Real-World Examples

See [examples.md](examples.md).
