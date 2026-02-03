# Skill: Craft Router Navigation

> "Router owns all navigation. Period."

## The Pattern

Inertia router handles all page transitions and state-changing actions.

```typescript
import { router } from '@inertiajs/vue3'

// Navigation
router.get(route('invoices.index'))
router.visit(route('invoices.show', { invoice: id }))

// State-changing actions
router.post(route('invoices.issue', { invoice: id }), {})
router.delete(route('invoices.destroy', { invoice: id }))

// Partial reload
router.reload({ only: ['invoice', 'lineItems'] })
```

## The Methods

| Method            | Use Case                                   |
|-------------------|--------------------------------------------|
| `router.get()`    | Navigation without data                    |
| `router.visit()`  | Navigation (explicit, same as get)         |
| `router.post()`   | State-changing action (non-form)           |
| `router.delete()` | Deletion                                   |
| `router.reload()` | Refresh current page props                 |

## The Rules

1. **No fetch for navigation**: Always use router
2. **Trust defaults**: Skip `preserveState/preserveScroll` unless needed
3. **Partial reload for performance**: Specify `only: []` when refreshing
4. **Post for actions**: Use `router.post()` for non-form state changes

## The Anti-Patterns

| Don't                             | Do                                  |
|-----------------------------------|-------------------------------------|
| `fetch()` then navigate           | `router.get()`                      |
| `window.location.href = ...`      | `router.visit()`                    |
| Full reload for one prop          | `router.reload({ only: [...] })`    |
| `preserveState: true` everywhere  | Rely on Inertia defaults            |
