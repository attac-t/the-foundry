---
name: craft-action
description: Crafting an Action. The heart of business logic.
---

# Skill: Craft Action

> "An Action is a single unit of business logic."

## The Standard

1. **One Public Method**: `execute()`.
2. **Return Type**: Model or void. Never DTO or Response.
3. **Inject Actions**: Use `__construct` for dependencies.
4. **Accept Data**: DTOs or primitives in `execute()`.
5. **Stateful Execution**: Store input on `$this` and chain private methods. Actions are short-lived objects — statefulness during a single `execute()` call is the intended design. Do NOT pass parameters between private methods.

## The Anti-Patterns

| ❌ Don't                       | ✅ Do                          | Why                       |
|-------------------------------|-------------------------------|---------------------------|
| `DB::transaction()` in Action | Transaction in Controller     | Prevents composition      |
| Validate in Action            | Validate in FormRequest       | Single responsibility     |
| Wrap `Model::create()` only   | Add real logic or skip Action | No value added            |
| Return DTO/Response           | Return Model or void          | Actions aren't HTTP-aware |
| Pass params to private methods| Store on `$this`, chain methods| Verbose signatures, no fluency|

## Real-World Examples

See [examples/](examples/).
