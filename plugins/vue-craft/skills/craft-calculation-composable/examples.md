# Calculation Composable: Examples

---

## Reactive Calculation

```typescript
interface UseInvoiceCalculationOptions {
  lineItems: MaybeRefOrGetter<InvoiceLineItem[]>
  taxRate: MaybeRefOrGetter<number>
}

const useInvoiceCalculation = (options: UseInvoiceCalculationOptions) => {
  const { lineItems, taxRate } = options

  const subTotal = computed(() =>
    toValue(lineItems).reduce(
      (sum, item) => add({ money1: sum, money2: item.line_total }),
      zero(DEFAULT_CURRENCY)
    )
  )

  const taxTotal = computed(() =>
    multiply({ money: subTotal.value, multiplier: toValue(taxRate) / 100 })
  )

  const total = computed(() => add({ money1: subTotal.value, money2: taxTotal.value }))

  return { subTotal, taxTotal, total }
}
```

---

## Form Model Sync

```typescript
const useInvoiceCalculation = (options: CalculationOptions) => {
  const { lineItems, formModel } = options
  const total = computed(() => calculateTotal(toValue(lineItems)))

  // Sync to form model when it changes
  if (formModel) {
    watchEffect(() => { formModel.value.total = total.value })
  }

  return { total }
}
```

---

## Tiered Logic

```typescript
const useCreditCheck = (options: UseCreditCheckOptions) => {
  const utilization = computed(() => {
    const limit = toValue(options.creditLimit)
    if (!limit || limit.amount === 0) return null

    const projected = add({ money1: toValue(options.currentBalance), money2: toValue(options.invoiceTotal) })
    return (projected.amount / limit.amount) * 100
  })

  const tier = computed(() => {
    const util = utilization.value
    if (util === null) return null
    if (util < 70) return 0
    if (util < 90) return 2
    if (util < 100) return 3
    return util === 100 ? 4 : 5
  })

  return { utilization, tier }
}
```
