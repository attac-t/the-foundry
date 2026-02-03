# Examples: Router Navigation

---

## Import

```typescript
import { router } from '@inertiajs/vue3'
```

---

## Basic Navigation

```typescript
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

---

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

// Void invoice with data
router.post(
  route('admin.invoices.void', { invoice: invoiceId }),
  { reason: voidReason }
)
```

---

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

---

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

---

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

---

## Methods Reference

```typescript
router.get(url)              // GET - navigation
router.visit(url)            // GET - explicit navigation
router.post(url, data, opts) // POST - state-changing
router.put(url, data, opts)  // PUT - update
router.delete(url, opts)     // DELETE - removal
router.reload(opts)          // Refresh current page props
```

---

## Trust Defaults

```typescript
// Don't do this - unnecessary
router.post(url, data, {
  preserveState: true,
  preserveScroll: true
})

// Do this - Inertia handles it
router.post(url, data)

// Only override when you need different behavior
router.post(url, data, {
  preserveState: false  // Force state reset
})
```
