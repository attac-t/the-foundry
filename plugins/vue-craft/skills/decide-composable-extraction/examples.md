# Composable Extraction: Examples

When to extract vs keep inline.

---

## Extract: Credit Check Logic

**Why?** Complex. Testable. Reusable in Show/Edit pages.

```typescript
// Before: 50+ lines in component
const creditLimit = computed(() => ...)
const totalDue = computed(() => ...)
const projectedDue = computed(() => ...)
const utilizationPercent = computed(() => ...)
const tier = computed(() => {
  if (already over) return 5
  if (will exceed) return 4
  if (90-99%) return 3
  // ... etc
})

// After: useInvoiceCreditCheck
const { creditCheck } = useInvoiceCreditCheck({
  entity: selectedUser,
  entityType: ref('user'),
  invoiceTotal
})
```

---

## Keep Inline: Simple Derived State

**Why?** Single use. One computed. No test value.

```typescript
// Keep inline — trivial derivation
const isCustomerSelected = computed(
  () => !!formData.value.user_id || !!formData.value.company_id
)

// Keep inline — component-specific
const pageTitle = computed(
  () => isCloning.value ? 'Clone Invoice' : 'New Invoice'
)
```

---

## The Rule of Three

1. **First time**: Write inline.
2. **Second time**: Note the duplication.
3. **Third time**: Extract.

```typescript
// Saw this pattern in New.vue, Edit.vue, Show.vue?
// Time to extract.
```
