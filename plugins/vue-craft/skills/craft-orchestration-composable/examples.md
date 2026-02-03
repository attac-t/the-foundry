# Orchestration Composable: Examples

---

## Detection + Dispatch

```typescript
interface CloneDetection {
  hasDeletedItems: boolean
  validOrderItemIds: number[]
  deletedOrderItemIds: number[]
}

const detectDeletedItems = (orderItems: OrderItem[]): CloneDetection => {
  const valid: number[] = []
  const deleted: number[] = []

  for (const item of orderItems) {
    ;(item.orderable?.deleted_at ? deleted : valid).push(item.id)
  }

  return { hasDeletedItems: deleted.length > 0, validOrderItemIds: valid, deletedOrderItemIds: deleted }
}

const useCloneInvoice = () => {
  const cloneInvoice = (params: CloneInvoiceParams): void => {
    const detection = detectDeletedItems(params.orderItems)

    if (!detection.hasDeletedItems) {
      showStandardConfirmation(params)
      return
    }

    if (detection.validOrderItemIds.length === 0) {
      showAllDeletedWarning()
      return
    }

    showDeletedItemsWarning(params, detection)
  }

  return { cloneInvoice }
}
```

---

## Hierarchical Flow

```typescript
const handleSave = async () => {
  // Layer 1: Form validation
  await zodRootCtx.validateAll()
  if (zodRootCtx.isAnyInvalid) return showValidationError()

  // Layer 2: Business rule confirmation
  if (creditConfirmation.requiresConfirmation.value) {
    const confirmed = await creditConfirmation.requestConfirmation()
    if (!confirmed) return
  }

  // Layer 3: Action confirmation
  showConfirmation({ message: 'Save changes?', accept: () => submitForm() })
}
```
