# Skill: Craft Operation Composable

> "CRUD with dual variants: Inertia for pages, API for chains."

## The Pattern

Operation composables handle CRUD with notifications and processing state.

```typescript
const useCreateInvoice = () => {
  const createDraft = (form: InertiaForm<T>, options?: Options) => {
    const notification = useEntityNotification({
      action: 'Creating',
      entityName: 'invoice'
    })

    notification.startOperation()

    form.post(route('invoices.store'), {
      onSuccess: () => {
        notification.onSuccess()
        options?.onSuccess?.()
      },
      onError: () => {
        notification.onError()
        options?.onError?.()
      },
      onFinish: () => notification.onFinish()
    })
  }

  return { createDraft }
}
```

## The Dual Variants

```typescript
// Inertia variant: Page reload after operation
updateDraft(params, form, options)

// API variant: Promise for chaining
const success = await updateDraftApi(params, data, options)
if (success) {
  await issueDraftApi(params)
  router.reload()
}
```

## The Structure

```
use-invoice-operation/
├── use-create/useCreateInvoice.ts    # createDraft
├── use-update/useUpdateInvoice.ts    # updateDraft, updateDraftApi
├── use-delete/useDeleteInvoice.ts    # deleteDraft
├── use-issue/useIssueInvoice.ts      # issueDraft, issueDraftApi
└── useInvoiceOperation.types.ts
```

## The Rules

1. **Processing state**: Track with `isProcessing` ref for UI feedback
2. **Notification lifecycle**: Always use `useEntityNotification`
3. **Options passthrough**: Chain user callbacks after notification
4. **Delete navigates away**: Use `router.visit()` after successful delete
5. **API variant returns boolean**: `true` for success, `false` for error
6. **Silent failure check**: In `onFinish`, check processing state — if still true, trigger error
7. **Reload after Inertia update**: Call `router.reload()` in onSuccess for fresh server state
8. **Readonly params**: Mark operation params as `readonly` to prevent mutation

## The Anti-Patterns

| Don't                              | Do                                      |
|------------------------------------|-----------------------------------------|
| Skip notification composable       | Always use `useEntityNotification`      |
| Mix page reload with chaining      | Pick variant based on flow              |
| Forget processing state            | Track with ref for UI feedback          |
| Stay on page after delete          | Navigate to index                       |
| Skip `form.processing` check       | Check in onFinish for silent failures   |
| Manual page refresh                | `router.reload()` preserves Inertia     |
