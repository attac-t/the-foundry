# Skill: Decide Inertia vs API

> "Page reload or Promise chain?"

## The Heuristic

```
Need page reload after?     → Inertia variant
Need to chain operations?   → API variant
Single operation, done?     → Inertia variant
Save then issue then reload? → API variant
```

## Quick Test

Ask: "What happens after this operation completes?"

- **Page reloads anyway** → Inertia
- **Another operation follows** → API
- **User sees fresh server state** → Inertia
- **Need return value for next step** → API

## The Comparison

| Inertia Variant                    | API Variant                          |
|------------------------------------|--------------------------------------|
| `form.post()` / `router.post()`    | `api.create()` returns Promise       |
| Page reloads on success            | Manual `router.reload()` needed      |
| Simpler callback flow              | Can chain with `await`               |
| Standard CRUD operations           | Multi-step workflows                 |

## When Inertia

```typescript
// Single operation - page reloads after
updateDraft(params, form)

// Delete - navigates away
deleteDraft(params)

// Action without chaining
router.post(route('invoices.archive', { invoice: id }))
```

## When API

```typescript
// Save, then issue, then reload
const saved = await updateDraftApi(params, form.data())
if (saved) {
  const issued = await issueDraftApi(params)
  if (issued) {
    router.reload()
  }
}
```

## The Anti-Patterns

| Don't                                    | Do                               |
|------------------------------------------|----------------------------------|
| API for simple create/update             | Inertia variant                  |
| Inertia when chaining operations         | API variant with await           |
| Manual reload after Inertia operation    | Let Inertia handle it            |
| Forget reload after API chain            | Always `router.reload()` at end  |
