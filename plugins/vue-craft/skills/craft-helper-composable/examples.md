# Helper Composable: Examples

Helper patterns from production code.

---

## The Pattern

### Section-Organized Returns
**Why?** Visual grouping. Easy to scan.

```typescript
const useInvoiceHelper = (invoice: MaybeRefOrGetter<Invoice>) => {
  const data = computed(() => toValue(invoice))
  const status = computed(() => data.value.status)

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS PREDICATES
  // ═══════════════════════════════════════════════════════════════════════════
  const isDraft = computed(() => status.value === INVOICE_STATUS.DRAFT)
  const isSent = computed(() => status.value === INVOICE_STATUS.SENT)
  const isPaid = computed(() => status.value === INVOICE_STATUS.PAID)
  const isOverDue = computed(() => status.value === INVOICE_STATUS.OVER_DUE)
  const isVoid = computed(() => status.value === INVOICE_STATUS.VOID)
  const isIssued = computed(() => isSent.value || isPaid.value || isOverDue.value)

  // ═══════════════════════════════════════════════════════════════════════════
  // CUSTOMER INFO
  // ═══════════════════════════════════════════════════════════════════════════
  const customerName = computed(() => data.value.customer?.full_name ?? 'Unknown')
  const customerEmail = computed(() => data.value.customer?.email ?? '')
  const hasCustomer = computed(() => !!data.value.customer)

  // ═══════════════════════════════════════════════════════════════════════════
  // DISPLAY VALUES
  // ═══════════════════════════════════════════════════════════════════════════
  const formattedTotal = computed(() => data.value.total.formatted)
  const formattedDueDate = computed(() => formatDate(data.value.due_date))

  return {
    // Status
    isDraft, isSent, isPaid, isOverDue, isVoid, isIssued,
    // Customer
    customerName, customerEmail, hasCustomer,
    // Display
    formattedTotal, formattedDueDate
  }
}
```

---

## Common Scenarios

### Compound Predicates
**Why?** Combine simple predicates for complex conditions.

```typescript
// Simple predicates
const isDraft = computed(() => status.value === INVOICE_STATUS.DRAFT)
const isSent = computed(() => status.value === INVOICE_STATUS.SENT)
const isPaid = computed(() => status.value === INVOICE_STATUS.PAID)

// Compound predicate
const isIssued = computed(() => isSent.value || isPaid.value || isOverDue.value)
const canEdit = computed(() => isDraft.value && !isSubmitting.value)
```

### Usage in Template
**Why?** Clean template logic.

```vue
<template>
  <!-- Bad: inline condition -->
  <Badge v-if="invoice.status === 'DRAFT' || invoice.status === 'SENT'" />

  <!-- Good: named predicate -->
  <Badge v-if="isDraft || isSent" />
</template>

<script setup>
const { isDraft, isSent, customerName } = useInvoiceHelper(invoice)
</script>
```
