# Const Type: Examples

Const object patterns from production code.

---

## The Pattern

### Status Const + Type
**Why?** Iterable values. Type-safe usage.

```typescript
const INVOICE_STATUS = {
  DRAFT: 'DRAFT',
  SENT: 'SENT',
  PAID: 'PAID',
  OVER_DUE: 'OVER_DUE',
  VOID: 'VOID'
} as const

type InvoiceStatus = (typeof INVOICE_STATUS)[keyof typeof INVOICE_STATUS]

export { INVOICE_STATUS }
export type { InvoiceStatus }
```

### Usage
```typescript
// Type-safe comparison
if (invoice.status === INVOICE_STATUS.DRAFT) { ... }

// Iteration (impossible with enum)
const statusOptions = Object.values(INVOICE_STATUS)

// Type inference
const status: InvoiceStatus = 'DRAFT'  // ✓
const status: InvoiceStatus = 'INVALID'  // ✗ Type error
```

---

## Common Scenarios

### Config Object
**Why?** Related constants grouped together.

```typescript
const INVOICE_SCALE_CONFIG = {
  CURRENCY_SCALE: 2,
  DEFAULT_CURRENCY: { code: 'EUR', scale: 2 },
  TOTALS: {
    SUB_TOTAL: 2,
    TAX_TOTAL: 2,
    TOTAL: 2
  },
  LINE_ITEMS: {
    UNIT_PRICE: 2,
    LINE_TOTAL: 2
  }
} as const

type CurrencyScale = typeof INVOICE_SCALE_CONFIG.CURRENCY_SCALE
```

### Morph Types
**Why?** Polymorphic identifiers.

```typescript
const MORPH_TYPES = {
  USER: 'user',
  LOCATION: 'location',
  DAY: 'day',
  WEEK: 'week',
  MONTH: 'month'
} as const

type MorphType = (typeof MORPH_TYPES)[keyof typeof MORPH_TYPES]
```

### Order Item Keys
**Why?** Dynamic component dispatch.

```typescript
const ORDER_ITEM_ITEM_KEYS = {
  VARIANT: 'variant',
  FEE: 'fee',
  DISCOUNT: 'discount'
} as const

type OrderItemItemKeys = (typeof ORDER_ITEM_ITEM_KEYS)[keyof typeof ORDER_ITEM_ITEM_KEYS]
```
