---
name: craft-zod-schema
description: UI validation schemas. Object shape. Cross-field refine.
---

# Skill: Craft Zod Schema

> "Schemas are executable documentation."

## The Standard

1. **UI validation only**: Schemas validate form input, not API contracts.
2. **Object shape**: Define shape with `z.object({ ... })`.
3. **Cross-field refine**: Use `.refine()` for rules spanning multiple fields.
4. **Path targeting**: Refine errors target specific fields via `path` option.

## The Anti-Patterns

| Don't              | Do                   | Why                |
|--------------------|----------------------|--------------------|
| API validation     | UI validation        | Different concerns |
| Nested refinements | Flat refine chain    | Readable           |
| Generic error      | Field-targeted error | UX                 |
| Schema in component | Separate file        | Reusable           |

## Real-World Examples

See [examples.md](examples.md).
