---
name: craft-dto
description: Crafting DTOs with Spatie Laravel Data v4.
---

# Skill: Craft DTO

> "Type safety isn't a luxury; it's requirements documentation."

## Before You Start

1. **Read the docs**: [spatie.be/docs/laravel-data/v4](https://spatie.be/docs/laravel-data/v4)
2. **Explore the namespace**: `vendor/spatie/laravel-data/src` to avoid hallucination.

## The Standard

1. **Two Types**: `Create{Model}Data` (input) vs `{Model}Data` (output/representation).
2. **Native Collection**: Prefer `Collection` over `DataCollection`. Use `$data->all()`.
3. **Lazy Relations**: `#[AutoWhenLoadedLazy]` for conditional relationship inclusion.
4. **Immutable**: Mutate via `->with()`, never direct assignment.

## The Anti-Patterns

| ❌ Don't | ✅ Do | Why |
|----------|-------|-----|
| `DataCollection` | Native `Collection` | v4 preferred for basic nesting. |
| `$dto->except('id')->toArray()` | `$dto->all()` | Cleaner. Handle Optional in action. |
| Omit `#[AutoWhenLoadedLazy]` | Always use on relations | Avoids triggering lazy loads. |
| `#[WithCast]` on output DTO | Only on request DTOs | Casts are for input direction only. |
| Guess API | Read docs + namespace | Avoid hallucination. |
| Direct mutation | `->with()` | Immutability. |

## Real-World Examples

See [examples/](examples/).
