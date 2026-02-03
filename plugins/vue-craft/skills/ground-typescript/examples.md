# TypeScript: Examples

Type philosophy patterns and anti-patterns.

---

## Inference Patterns

### Let TypeScript Infer
**Why?** Redundant annotations add noise.

```typescript
// Bad: redundant annotation
const count: number = 0
const items: string[] = ['a', 'b', 'c']
const user: User = { id: 1, name: 'John' }

// Good: inference works
const count = 0
const items = ['a', 'b', 'c']
const user: User = { id: 1, name: 'John' }  // Keep: object literal needs type
```

### Explicit at Boundaries
**Why?** Public contracts are documentation.

```typescript
// Function boundaries: explicit
const calculateTotal = (items: LineItem[]): Money => {
  // Internal: inferred
  const subtotals = items.map(item => multiply(item.price, item.quantity))
  return sum(subtotals)
}
```

---

## Documentation Patterns

### JSDoc in Interfaces
**Why?** Interfaces are contracts. Document them.

```typescript
/**
 * Invoice domain model.
 * Backend: domain/Orders/Models/Invoice.php
 */
interface Invoice {
  /** Unique identifier (ULID) */
  id: string
  /** Invoice status */
  status: InvoiceStatus
  /** Line items on this invoice */
  line_items: InvoiceLineItem[]
  /** Total amount due */
  total: Money
}
```

### Named Exports for Types
**Why?** Explicit imports. No barrel file confusion.

```typescript
// Good: named exports
export type { Invoice, InvoiceLineItem }
export { INVOICE_STATUS }

// Bad: default export for types
export default interface Invoice { ... }
```

---

## Import Paths

```typescript
// Bad: relative imports break when files move
import { Invoice } from '../../../types/models/Invoice'
import { useInvoiceHelper } from '../../composables/use-invoice-helper'

// Good: absolute imports via alias
import type { Invoice } from '@/domains/invoices/types/models/Invoice'
import { useInvoiceHelper } from '@/domains/invoices/composables/use-invoice-helper'
```
