---
name: craft-const-type
description: Const objects with derived types. Single source of truth.
---

# Skill: Craft Const Type

> "One source. Two exports. Zero drift."

## The Standard

1. **Object first**: Define the const object with all values.
2. **Derive the type**: `type X = (typeof OBJ)[keyof typeof OBJ]`
3. **Separate exports**: Export const and type separately.
4. **SCREAMING_CASE**: Const objects use SCREAMING_CASE.

## The Anti-Patterns

| Don't            | Do                 | Why                               |
|------------------|--------------------|-----------------------------------|
| Enum             | `as const` object  | Objects are iterable, enums aren't |
| Duplicate values | Derive from const  | Single source of truth            |
| Type-first       | Object-first       | Values are the source             |
| Mixed export     | Separate exports   | Clarity                           |

## Real-World Examples

See [examples.md](examples.md).
