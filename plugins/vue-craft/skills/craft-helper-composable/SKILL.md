---
name: craft-helper-composable
description: Section-organized returns. Status predicates. Derived properties.
---

# Skill: Craft Helper Composable

> "Helpers surface what the entity knows about itself."

## The Standard

1. **Section dividers**: Visual separators for logical groupings.
2. **Status predicates**: `isDraft`, `isSent`, `isPaid` — boolean computeds.
3. **Derived properties**: `customerName`, `formattedTotal` — computed values.
4. **Flat return**: Return all properties at top level, not nested objects.

## The Anti-Patterns

| Don't                    | Do                     | Why                 |
|--------------------------|------------------------|---------------------|
| `helper.status.isDraft`  | `helper.isDraft`       | Flat is simpler     |
| Inline conditions        | Named predicates       | Readable, testable  |
| Repeat derivations       | Centralize in helper   | Single source       |
| Mixed concerns           | Section dividers       | Visual organization |

## Real-World Examples

See [examples.md](examples.md).
