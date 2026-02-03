# Util vs Composable: Examples

Pure logic vs reactive logic.

---

## Util: Money Operations

**Why?** Pure math. No Vue. Same input = same output.

```typescript
// utils/money-util/moneyUtil.ts
const add = ({ money1, money2 }: AddParams): MoneyModel => {
  // Pure calculation
  return {
    amount: money1.amount + money2.amount,
    currency: money1.currency,
    scale: money1.scale,
    formatted: null
  }
}

// Can test without Vue
expect(add({ money1: m1, money2: m2 })).toEqual(expected)
```

---

## Composable: Invoice Calculation

**Why?** Accepts refs. Returns computed. Reactive updates.

```typescript
// composables/use-invoice-calculation/useInvoiceCalculation.ts
const useInvoiceCalculation = (options: Options) => {
  // Reactive input
  const lineItems = computed(() => toValue(options.lineItems))

  // Reactive output
  const subTotal = computed(() => {
    return lineItems.value.reduce(
      (sum, item) => add({ money1: sum, money2: item.sub_total }),
      zero({ currencyCode: 'EUR' })
    )
  })

  return { subTotal, taxTotal, total }
}
```

---

## Util: Clone Transform

**Why?** Pure transformation. No reactivity needed.

```typescript
// utils/clone-invoice/cloneInvoiceTransform.ts
const transformInvoiceForClone = (
  updateRequest: UpdateInvoiceRequest,
  options: CloneInvoiceOptions = {}
): CreateInvoiceRequest => {
  // Pure transformation — returns new object
  return {
    ...updateRequest,
    id: null,
    invoice_date: options.invoiceDate ?? getTodayYmd()
  }
}
```

---

## Composable: Credit Check

**Why?** Watches inputs. Updates tier reactively.

```typescript
// composables/use-invoice-credit-check/useInvoiceCreditCheck.ts
const useInvoiceCreditCheck = (options: Options) => {
  // Reactive: updates when entity/total changes
  const creditCheck = computed(() => {
    const entity = toValue(options.entity)
    const total = toValue(options.invoiceTotal)

    if (!entity?.credit_limit) return null

    return calculateTier(entity, total)
  })

  return { creditCheck }
}
```

---

## Decision Tree

```
Does it use ref(), computed(), or watch()?
├─ Yes → Composable
└─ No → Does it need Vue lifecycle hooks?
        ├─ Yes → Composable
        └─ No → Util
```
