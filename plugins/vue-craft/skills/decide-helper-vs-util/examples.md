# Helper vs Util: Examples

Reactive helpers vs pure utilities.

---

## Helper: Invoice Helper

**Why?** Returns computed predicates. Reactive to invoice changes.

```typescript
// domains/invoices/composables/use-invoice-helper/useInvoiceHelper.ts
const useInvoiceHelper = (invoice: MaybeRefOrGetter<Invoice>) => {
  const status = computed(() => toValue(invoice).status)

  // Reactive predicates
  const isDraft = computed(() => status.value === INVOICE_STATUS.DRAFT)
  const isSent = computed(() => status.value === INVOICE_STATUS.SENT)
  const isPaid = computed(() => status.value === INVOICE_STATUS.PAID)
  const isVoid = computed(() => status.value === INVOICE_STATUS.VOID)

  // Reactive derivations
  const customerName = computed(() => toValue(invoice).user?.full_name ?? 'Unknown')

  return { isDraft, isSent, isPaid, isVoid, customerName }
}
```

---

## Util: Money Operations

**Why?** Pure math. No Vue. Static calculation.

```typescript
// utils/money-util/moneyUtil.ts
const add = ({ money1, money2 }: AddParams): MoneyModel => ({
  amount: money1.amount + money2.amount,
  currency: money1.currency,
  scale: money1.scale,
  formatted: null
})

const formatWithSymbol = ({ money }: FormatParams): string => {
  return `${CURRENCY_SYMBOLS[money.currency]}${toMajor(money)}`
}
```

---

## Helper: Session Helper (Hypothetical)

**Why?** Reactive checks against session state.

```typescript
const useWorkSessionHelper = (session: MaybeRefOrGetter<WorkSession>) => {
  const isActive = computed(() => toValue(session).is_active)
  const isCompleted = computed(() => !isActive.value && toValue(session).ended_at)
  const duration = computed(() => formatDuration(toValue(session).duration_minutes))

  return { isActive, isCompleted, duration }
}
```

---

## Util: Date Formatting

**Why?** Pure transformation. No reactivity needed.

```typescript
// utils/date-util/dateUtil.ts
const formatDayDisplayName = (isoDate: string): string => {
  const date = DateTime.fromISO(isoDate)
  if (date.hasSame(DateTime.now(), 'day')) return 'Today'
  if (date.hasSame(DateTime.now().minus({ days: 1 }), 'day')) return 'Yesterday'
  return date.toFormat('EEEE')  // "Monday", "Tuesday", etc.
}
```

---

## Decision Tree

```
Does it return computed() or ref()?
├─ Yes → Helper composable (domains/{domain}/composables/)
└─ No → Is it domain-specific?
        ├─ Yes → Domain util (domains/{domain}/utils/)
        └─ No → Global util (utils/)
```
