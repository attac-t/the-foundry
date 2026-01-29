---
name: craft-value-object
description: Crafting Value Objects. Immutable, serialization-safe.
---

# Skill: Craft Value Object

> "A value object is defined by its attributes, not its identity."

## The Standard

1. **Immutable**: `readonly class`. No setters. Clone to modify.
2. **Self-Validating**: Throw on invalid construction.
3. **Serializable**: Must survive queue serialization. No closures.
4. **Equality by Value**: Two VOs with same attributes are equal.

## The Anti-Patterns

| ❌ Don't               | ✅ Do                        | Why                         |
|-----------------------|-----------------------------|-----------------------------|
| Mutable properties    | `readonly` class            | VOs don't change            |
| Skip validation       | Validate in constructor     | Invalid VOs shouldn't exist |
| Complex dependencies  | Primitives + other VOs      | Must serialize cleanly      |
| Entity with no ID     | Use VO intentionally        | Different concepts          |

## Real-World Examples

See [examples.md](examples.md).
