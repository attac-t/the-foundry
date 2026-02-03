# Composable Test: Examples

---

## Helper Factories

```typescript
const createMoney = (amount: number): MoneyModel => ({
  amount, currency: 'EUR', scale: 2
})

const createUser = (creditLimit: number, totalDue: number): User => ({
  id: '1',
  credit_limit: createMoney(creditLimit),
  due_invoices: { total_due: createMoney(totalDue) }
}) as User
```

---

## Reactive Assertions

```typescript
it('updates reactively when invoice total changes', () => {
  const invoiceTotal = ref(createMoney(2000))
  const { creditCheck } = useInvoiceCreditCheck({
    entity: ref(createUser(10000, 5000)),
    invoiceTotal
  })

  expect(creditCheck.value?.tier).toBe(2)

  invoiceTotal.value = createMoney(4000)
  expect(creditCheck.value?.tier).toBe(3)
})
```

---

## Tier-Based Structure

```typescript
it('returns tier 0 for healthy utilization (<70%)', () => { ... })
it('returns tier 2 for 70-89% projected utilization', () => { ... })
it('returns tier 4 when invoice will exceed limit', () => { ... })
```

---

## Null Edge Cases

```typescript
it('returns null when entity is null', () => {
  const { creditCheck } = useInvoiceCreditCheck({
    entity: ref(null),
    invoiceTotal: ref(createMoney(1000))
  })
  expect(creditCheck.value).toBeNull()
})
```
