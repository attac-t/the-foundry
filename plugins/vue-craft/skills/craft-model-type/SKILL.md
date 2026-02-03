---
name: craft-model-type
description: Domain model types. Rich JSDoc. Backend reference.
---

# Skill: Craft Model Type

> "The model is the contract between frontend and backend."

## The Standard

1. **Backend reference**: Document the corresponding backend model in JSDoc header.
2. **Property documentation**: Every property gets a JSDoc comment.
3. **Separate from response**: Domain model ≠ API response. Transform at the boundary.
4. **Named exports**: `export type { Invoice }` — no default exports.

## The Anti-Patterns

| Don't                            | Do                        | Why                       |
|----------------------------------|---------------------------|---------------------------|
| Undocumented interfaces          | JSDoc on every property   | Types are documentation   |
| `InvoiceResponse` in components  | `Invoice` domain model    | Decouple from API shape   |
| Default export                   | Named export              | Explicit imports          |
| Mix with request types           | Separate files            | Different concerns        |

## Real-World Examples

See [examples.md](examples.md).
