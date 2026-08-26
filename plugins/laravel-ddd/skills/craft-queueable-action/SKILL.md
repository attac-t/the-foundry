---
name: craft-queueable-action
description: Crafting Queueable Actions. Skip job boilerplate.
---

# Skill: Craft Queueable Action

> "If every action needs a job wrapper, eliminate the wrapper."

## The Standard

1. **Use Trait**: `QueueableAction` from `spatie/laravel-queueable-action`.
2. **Same Signature**: `execute()` stays the same. No job-specific code.
3. **Queue via Static**: `Action::onQueue()->execute($data)`.
4. **Configure Inline**: Chain `->onQueue('emails')`, `->delay()`, etc.

## The Anti-Patterns

| ❌ Don't               | ✅ Do                         | Why                       |
| --------------------- | ---------------------------- | ------------------------- |
| Job class per action  | `Action::onQueue()`          | Eliminates boilerplate    |
| Queue logic in action | Chain methods before execute | Single responsibility     |
| Forget serialization  | Use models/primitives only   | Jobs serialize parameters |

## Real-World Examples

See [examples.md](examples.md).
