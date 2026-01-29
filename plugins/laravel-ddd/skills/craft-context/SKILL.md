---
name: craft-context
description: Crafting Context Objects. Parameter encapsulation for complex operations.
---

# Skill: Craft Context

> "When an action needs too many parameters, the parameters become the object."

## The Standard

1. **Named Constructors**: `::forProvider()`, `::forBatch()`. Intent in the name.
2. **Encapsulate Configuration**: Dates, flags, identifiers—grouped, typed.
3. **Immutable**: Set once, read many. No setters.
4. **Passed Through Chains**: Context flows through action composition.

## The Anti-Patterns

| ❌ Don't                     | ✅ Do                          | Why                           |
|-----------------------------|-------------------------------|-------------------------------|
| 5+ action parameters        | Context object                | Clarity, maintainability      |
| Generic constructor         | Named constructors            | Intent is explicit            |
| Mutable context             | Immutable properties          | Prevents bugs in long chains  |
| Array of options            | Typed properties              | IDE support, validation       |

## Real-World Examples

See [examples.md](examples.md).
