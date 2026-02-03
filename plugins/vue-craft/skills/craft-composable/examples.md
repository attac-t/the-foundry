# Composable: Examples

---

## Directory Structure

```
composables/
└── use-invoice-calculation/
    ├── __tests__/
    │   └── useInvoiceCalculation.test.ts
    ├── useInvoiceCalculation.ts
    └── useInvoiceCalculation.types.ts
```

---

## Types Separation

```typescript
// useInvoiceCalculation.types.ts
interface UseInvoiceCalculationOptions {
  lineItems: MaybeRefOrGetter<InvoiceLineItem[]>
  taxRate: MaybeRefOrGetter<number>
}

interface UseInvoiceCalculationReturn {
  subTotal: ComputedRef<Money>
  taxTotal: ComputedRef<Money>
  total: ComputedRef<Money>
}

export type { UseInvoiceCalculationOptions, UseInvoiceCalculationReturn }
```

---

## Options + Return Pattern

```typescript
// Options object (named params, extensible)
const useCalculation = (options: UseCalculationOptions) => {
  const { lineItems, taxRate, currency = 'EUR' } = options
  // ...
}

// Return object (destructure what you need)
const { total, subTotal, taxTotal } = useCalculation(options)
```

---

## Flexible Inputs

```typescript
import { toValue, type MaybeRefOrGetter } from 'vue'

interface Options {
  price: MaybeRefOrGetter<number>
  quantity: MaybeRefOrGetter<number>
}

const useLineTotal = (options: Options) => {
  const total = computed(() => toValue(options.price) * toValue(options.quantity))
  return { total }
}
```
