# Examples: Operation Composable

---

## Directory Structure

```
domains/invoices/composables/
└── use-invoice-operation/
    ├── use-create/useCreateInvoice.ts
    ├── use-update/useUpdateInvoice.ts
    ├── use-delete/useDeleteInvoice.ts
    ├── use-issue/useIssueInvoice.ts
    ├── use-void/useVoidInvoice.ts
    └── useInvoiceOperation.types.ts
```

---

## Create Operation

```typescript
export const useCreateInvoice = () => {
  const createDraft = (
    form: InertiaForm<CreateInvoiceRequest>,
    options?: InvoiceOperationOptions
  ) => {
    const notification = useEntityNotification({
      action: 'Creating',
      entityName: 'invoice draft'
    })

    notification.startOperation()

    form.post(route('admin.invoices.store'), {
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

---

## Update with Dual Variants

```typescript
export const useUpdateInvoice = () => {
  const isSavingApi = ref(false)
  const invoicesApi = callInvoices()

  // Inertia variant - page reloads
  const updateDraft = (
    params: InvoiceOperationParams,
    form: InertiaForm<UpdateInvoiceRequest>,
    options?: InvoiceOperationOptions
  ) => {
    const notification = useEntityNotification({
      action: 'Updating',
      entityName: `invoice ${params.displayNumber}`
    })

    notification.startOperation()

    form.put(route('admin.invoices.update', { invoice: params.invoiceId }), {
      onSuccess: () => {
        notification.onSuccess()
        router.reload()
        options?.onSuccess?.()
      },
      onError: () => notification.onError(),
      onFinish: () => notification.onFinish()
    })
  }

  // API variant - returns Promise for chaining
  const updateDraftApi = (
    params: InvoiceOperationParams,
    data: UpdateInvoiceRequest,
    options?: InvoiceOperationOptions
  ): Promise<boolean> => {
    const notification = useEntityNotification({
      action: 'Saving',
      entityName: `invoice ${params.displayNumber}`
    })

    isSavingApi.value = true
    notification.startOperation()

    return invoicesApi
      .update({ id: params.invoiceId, body: data })
      .then(() => {
        notification.onSuccess()
        options?.onSuccess?.()
        return true
      })
      .catch(() => {
        notification.onError()
        options?.onError?.()
        return false
      })
      .finally(() => {
        isSavingApi.value = false
        notification.onFinish()
      })
  }

  return { updateDraft, updateDraftApi, isSavingApi }
}
```

---

## Delete with Navigation

```typescript
export const useDeleteInvoice = () => {
  const isDeleting = ref(false)

  const deleteDraft = (
    params: InvoiceOperationParams,
    options?: InvoiceOperationOptions
  ) => {
    const notification = useEntityNotification({
      action: 'Deleting',
      entityName: `invoice ${params.displayNumber}`
    })

    isDeleting.value = true
    notification.startOperation()

    router.delete(
      route('admin.invoices.destroy', { invoice: params.invoiceId }),
      {
        onSuccess: () => {
          isDeleting.value = false
          notification.onSuccess()
          router.visit(route('admin.invoices.index'))  // Navigate away
          options?.onSuccess?.()
        },
        onError: () => {
          isDeleting.value = false
          notification.onError()
          options?.onError?.()
        },
        onFinish: () => notification.onFinish()
      }
    )
  }

  return { deleteDraft, isDeleting }
}
```

---

## Silent Failure Check

```typescript
// CRITICAL: Check processing state in onFinish
// If still true, neither onSuccess nor onError fired

form.put(route('invoices.update', { invoice: id }), {
  onSuccess: () => {
    notification.onSuccess()
    options?.onSuccess?.()
  },
  onError: () => {
    notification.onError()
    options?.onError?.()
  },
  onFinish: () => {
    notification.onFinish()
    // Silent failure detection
    if (form.processing) {
      options?.onError?.()
    }
  }
})
```

---

## Type Definitions

```typescript
// Params are readonly - prevent mutation within operations
interface InvoiceOperationParams {
  readonly invoiceId: number | string
  readonly displayNumber: string
}

interface InvoiceOperationOptions {
  onSuccess?: () => void
  onError?: () => void
}
```

---

## Chaining API Variants

```typescript
// Save + Issue flow using API variants
const saveAndIssue = async () => {
  const saved = await updateDraftApi(params, form.data())
  if (!saved) return

  const issued = await issueDraftApi(params)
  if (!issued) return

  router.reload()  // Refresh with issued state
}
```
