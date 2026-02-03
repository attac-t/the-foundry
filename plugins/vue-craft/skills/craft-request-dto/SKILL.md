---
name: craft-request-dto
description: Request DTOs with factory functions. Form state types.
---

# Skill: Craft Request DTO

> "DTOs are the shape of intent."

## The Standard

1. **Interface + Factory**: Every DTO has a `DEFAULT_*()` factory function.
2. **Partial type**: `type Partial{Entity} = Partial<{Entity}>` for form state.
3. **Factory trio**: `DEFAULT_NEW_*()` (partial), `DEFAULT_*()` (complete), `*ToFormData()` (model→form).
4. **Spread override**: Factory accepts `params?: Partial<T>` for overrides.

## The Anti-Patterns

| Don't                | Do               | Why                |
|----------------------|------------------|--------------------|
| Inline defaults      | Factory function | Reusable, testable |
| Single factory       | Trio pattern     | Different use cases |
| Mutation             | Spread override  | Immutability       |
| Mix with model types | Separate files   | Different concerns |

## Real-World Examples

See [examples.md](examples.md).
