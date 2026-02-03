# Examples: Operation Composable

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

## Update with API Variant

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

## Type Definitions

```typescript
interface InvoiceOperationParams {
  invoiceId: number
  displayNumber: string
}

interface InvoiceOperationOptions {
  onSuccess?: () => void
  onError?: () => void
}
```
