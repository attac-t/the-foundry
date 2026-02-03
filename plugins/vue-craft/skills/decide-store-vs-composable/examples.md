# Store vs Composable: Examples

Where state should live.

---

## Store: Clone Flow

**Why?** Data survives navigation from Show → New page.

```typescript
// Show.vue — set before navigation
invoiceStore.setClonedInvoice(transformedData)
router.visit('/invoices/new')

// New.vue — consume after navigation
const clonedData = invoiceStore.consumeClonedInvoice()
```

**Without store:** Data lost when Show.vue unmounts.

---

## Composable: Form Validation

**Why?** Validation state is local to form. Reset on unmount is correct.

```typescript
// Form component
const zodCtx = useRegisteredZodValidation(
  'invoice-form',
  InvoiceSchema,
  formData
)

// When component unmounts, validation state is garbage collected
// This is exactly what we want
```

---

## Store: Cached Users

**Why?** Users are shared across many components. Don't re-fetch.

```typescript
// Any component can access cached users
const usersStore = useUsersStore()
await usersStore.fetch()  // Only fetches once
const users = usersStore.users  // Same data everywhere
```

---

## Composable: Invoice Calculations

**Why?** Calculations are specific to this form instance.

```typescript
// Calculation composable — local to this form
const { subTotal, taxTotal, total } = useInvoiceCalculation({
  lineItems: computed(() => formData.value.line_items),
  formModel: formData
})

// Different invoice form = different calculations = different instance
```

---

## Decision Tree

```
Is state shared across sibling/unrelated components?
├─ Yes → Store
└─ No → Does state need to survive component unmount?
        ├─ Yes → Store
        └─ No → Composable
```
