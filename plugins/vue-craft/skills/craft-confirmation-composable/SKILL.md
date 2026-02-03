---
name: craft-confirmation-composable
description: Promise-based confirmations. Threshold watching. Auto-show dialogs.
---

# Skill: Craft Confirmation Composable

> "Await the user's intent."

## The Standard

1. **Promise-based**: `requestConfirmation()` returns `Promise<boolean>`.
2. **Threshold watching**: Track initial state, detect user-caused transitions.
3. **Auto-show**: Dialog appears automatically when threshold crossed.
4. **Cleanup**: Use `onScopeDispose` to stop watchers.

## The Anti-Patterns

| Don't                  | Do                            | Why             |
|------------------------|-------------------------------|-----------------|
| Callback hell          | `await requestConfirmation()` | Sequential flow |
| Always show dialog     | Threshold-based               | Only when needed |
| Manual watcher cleanup | `onScopeDispose`              | Automatic       |
| Global state           | Composable-scoped             | Encapsulated    |

## Real-World Examples

See [examples.md](examples.md).
