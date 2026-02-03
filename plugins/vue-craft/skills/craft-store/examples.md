# Store: Examples

---

## Setup Store

```typescript
export const useInvoiceStore = defineStore('invoiceStore', () => {
  // State
  const clonedInvoice = ref<CreateInvoiceRequest | undefined>()

  // Actions
  const setClonedInvoice = (invoice: CreateInvoiceRequest): void => {
    clonedInvoice.value = invoice
  }

  const consumeClonedInvoice = (): CreateInvoiceRequest | undefined => {
    const invoice = clonedInvoice.value
    clonedInvoice.value = undefined  // Clear after consuming
    return invoice
  }

  // Getters
  const hasClonedInvoice = computed(() => clonedInvoice.value !== undefined)

  return { clonedInvoice, setClonedInvoice, consumeClonedInvoice, hasClonedInvoice }
})
```

---

## Consume Pattern

```typescript
// Producer: set before navigation
invoiceStore.setClonedInvoice(transformedData)
router.visit('/invoices/new')

// Consumer: get and clear atomically
onMounted(() => {
  const clonedData = invoiceStore.consumeClonedInvoice()
  if (clonedData) formAgent.state.value = clonedData
})
```
