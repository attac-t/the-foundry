---
name: craft-queueable-action
description: Crafting Queueable Actions. Skip job boilerplate.
---

# Skill: Craft Queueable Action

> "If every action needs a job wrapper, eliminate the wrapper."

## The Standard

1. **Use Trait**: `QueueableAction` from `spatie/laravel-queueable-action`.
2. **Same Signature**: `execute()` stays the same. No job-specific code.
3. **Queue on the Instance**: `$action->onQueue()->execute($data)`. `onQueue()` is
   an instance method — inject the action or resolve it with `app()`.
4. **Name the Queue by Argument**: `$action->onQueue('emails')`. The proxy it
   returns exposes only `execute()`; connection, delay, and retries are properties
   and methods on the action itself.

## The Anti-Patterns

| ❌ Don't                          | ✅ Do                              | Why                       |
|----------------------------------|-----------------------------------|---------------------------|
| Job class per action             | `$action->onQueue()`              | Eliminates boilerplate    |
| `Action::onQueue()` statically   | Resolve, then call                | It is an instance method  |
| `->delay()` after `onQueue()`    | `$tries`/`backoff()` on the action | The proxy has no such method |
| Forget serialization             | Use models/primitives only        | Jobs serialize parameters |

## Real-World Examples

See [examples.md](examples.md).
