# Examples: Router Navigation

## Basic Navigation

```typescript
import { router } from '@inertiajs/vue3'

// Navigate to list
router.get(route('admin.invoices.index'))

// Navigate to show page
router.visit(route('admin.invoices.show', { invoice: invoiceId }))

// Navigate with query params
router.get(route('admin.invoices.index'), {
  search: searchTerm,
  status: 'draft'
})
```

## State-Changing Actions

```typescript
// Issue invoice (no form data, just action)
router.post(
  route('admin.invoices.issue', { invoice: invoiceId }),
  {},  // Empty data
  {
    onSuccess: () => notification.onSuccess(),
    onError: () => notification.onError()
  }
)

// Void invoice
router.post(
  route('admin.invoices.void', { invoice: invoiceId }),
  { reason: voidReason }
)
```

## Deletion with Redirect

```typescript
router.delete(
  route('admin.invoices.destroy', { invoice: invoiceId }),
  {
    onSuccess: () => {
      notification.onSuccess()
      router.visit(route('admin.invoices.index'))  // Navigate away
    },
    onError: () => notification.onError()
  }
)
```

## Partial Reload

```typescript
// Refresh only specific props
router.reload({ only: ['invoice'] })

// Refresh multiple props
router.reload({ only: ['invoice', 'lineItems', 'totals'] })

// After API operation completes
await updateDraftApi(params, data)
router.reload({ only: ['invoice'] })
```

## Callbacks Pattern

```typescript
router.post(route('invoices.archive', { invoice: id }), {}, {
  onBefore: () => {
    // Before request starts
    isProcessing.value = true
  },
  onSuccess: () => {
    notification.onSuccess()
  },
  onError: (errors) => {
    notification.onError()
    console.error(errors)
  },
  onFinish: () => {
    isProcessing.value = false
  }
})
```
