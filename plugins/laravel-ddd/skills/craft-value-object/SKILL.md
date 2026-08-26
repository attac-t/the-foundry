---
name: craft-value-object
description: Crafting Value Objects. Immutable, serialization-safe.
---

# Skill: Craft Value Object

> "Invalid objects should be impossible to create."

## The Standard

1. **Self-Validating**: Validate in constructor. Invalid state throws immediately.
2. **Immutable**: `readonly class`. No setters. Clone to modify.
3. **Defensive Construction**: Private constructor + named factories for controlled creation.
4. **Serializable**: Must survive queue serialization. No closures, no resources.

## The Anti-Patterns

| ❌ Don't              | ✅ Do                    | Why                         |
| -------------------- | ----------------------- | --------------------------- |
| Mutable properties   | `readonly` class        | VOs don't change            |
| Skip validation      | Validate in constructor | Invalid VOs shouldn't exist |
| Complex dependencies | Primitives + other VOs  | Must serialize cleanly      |
| Entity with no ID    | Use VO intentionally    | Different concepts          |

## Real-World Examples

See [examples/](examples/).
