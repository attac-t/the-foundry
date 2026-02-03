# Model Type: Examples

---

## Complete Model Interface

```typescript
/**
 * Invoice domain model.
 * Backend: domain/Orders/Models/Invoice.php
 */
interface Invoice {
  /** Unique identifier (ULID) */
  id: string
  /** Current invoice status */
  status: InvoiceStatus
  /** Invoice number for display (e.g., "INV-2024-0001") */
  invoice_number: string
  /** Date the invoice was issued */
  invoice_date: string
  /** Date payment is due */
  due_date: string
  /** Line items on this invoice */
  line_items: InvoiceLineItem[]
  /** Subtotal before tax */
  sub_total: Money
  /** Total tax amount */
  tax_total: Money
  /** Final total (sub_total + tax_total) */
  total: Money
  /** Associated order (optional) */
  order?: Order
  /** Customer who receives the invoice */
  customer?: User
  /** Company associated with invoice */
  company?: Company
}

export type { Invoice }
```

---

## Nested Models

```typescript
interface InvoiceLineItem {
  id: string
  quantity: number
  unit_price: Money
  line_total: Money
  orderable: Orderable
}
```

---

## Nullability

```typescript
interface Invoice {
  // Required: always present
  id: string
  status: InvoiceStatus

  // Optional: may be undefined
  customer?: User
  company?: Company

  // Nullable: explicitly null when empty
  notes: string | null
}
```
