---
name: craft-page-props
description: Page props interfaces. One per page type.
---

# Skill: Craft Page Props

> "Pages declare their dependencies."

## The Standard

1. **One interface per page**: `{Entity}IndexProps`, `{Entity}NewProps`, `{Entity}EditProps`, `{Entity}ShowProps`.
2. **Controller contract**: Props match what the controller provides.
3. **Colocate with domain**: `domains/{domain}/types/pages/{Entity}PagesProps.types.ts`.
4. **Named exports**: Export all page props from one file.

## The Anti-Patterns

| Don't                 | Do                  | Why                |
|-----------------------|---------------------|--------------------|
| Generic `PageProps`   | Specific per page   | Type safety        |
| Inline in page        | Separate file       | Reusable, testable |
| Props in `types/` root | `types/pages/`      | Organized          |
| Optional everything   | Required by default | Explicit contract  |

## Real-World Examples

See [examples.md](examples.md).
