---
name: craft-zod-registry
description: Cross-component validation. Provide/inject. Aggregate operations.
---

# Skill: Craft Zod Registry

> "One registry. Many validators. One truth."

## The Standard

1. **Parent provides**: `useZodValidationRegistry()` at page/form root.
2. **Children register**: `useRegisteredZodValidation()` auto-registers with parent.
3. **Aggregate validation**: `validateAll()` runs all registered validators.
4. **Auto-cleanup**: Validators unregister on component unmount.

## The Anti-Patterns

| Don't                 | Do                | Why            |
|-----------------------|-------------------|----------------|
| Manual coordination   | Registry pattern  | Centralized    |
| Forget cleanup        | Auto-unregister   | Memory safe    |
| Individual validation | `validateAll()`   | Consistent UX  |
| Callbacks             | Promise-based     | Async-friendly |

## Real-World Examples

See [examples.md](examples.md).
