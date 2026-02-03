# Lazy Loading: Examples

When to use `defineAsyncComponent`.

---

## Lazy: Conditional Section

**Why?** Only loads when customer is selected.

```typescript
const LazyTwnInvoiceLineItemsSection = defineAsyncComponent(
  () => import('@/domains/invoices/components/organisms/twn-invoice-line-items-section/TwnInvoiceLineItemsSection.vue')
)
```

```html
<LazyTwnInfoState v-if="!isCustomerSelected" />
<LazyTwnInvoiceLineItemsSection v-else />
```

---

## Lazy: Dialog

**Why?** Dialogs are hidden by default.

```typescript
const LazyTwnCreditLimitConfirmation = defineAsyncComponent(
  () => import('@/domains/invoices/components/molecules/twn-credit-limit-confirmation/TwnCreditLimitConfirmation.vue')
)
```

```html
<LazyTwnCreditLimitConfirmation
  v-model:visible="isDialogVisible"
/>
```

---

## Lazy: Sidebar Content

**Why?** Secondary content. Can load after main.

```typescript
const LazyTwnInvoiceBankingSection = defineAsyncComponent(
  () => import('@/domains/invoices/components/organisms/twn-invoice-banking-section/TwnInvoiceBankingSection.vue')
)
```

```html
<template #sidebar>
  <LazyTwnInvoiceBankingSection />
</template>
```

---

## Eager: Core Form

**Why?** Always visible. Critical path.

```typescript
// Direct import — no lazy loading
import TwnInvoiceForm from '@/domains/invoices/components/organisms/twn-invoice-form/TwnInvoiceForm.vue'
import TwnInvoiceActionButtons from '@/domains/invoices/components/organisms/twn-invoice-action-buttons/TwnInvoiceActionButtons.vue'
```

---

## Decision Tree

```
Is component rendered conditionally (v-if, v-show)?
├─ Yes → Lazy load
└─ No → Is it a heavy component tree?
        ├─ Yes → Consider lazy loading
        └─ No → Eager import
```
