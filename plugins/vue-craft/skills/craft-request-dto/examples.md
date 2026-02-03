# Request DTO: Examples

Factory patterns from production code.

---

## The Pattern

### Factory Trio
**Why?** Different defaults for different contexts.

```typescript
/**
 * Zod schema for form validation
 */
const FeeSchema = z.object({
  id: z.number().nullish(),
  name: preprocessEmptyAsUndefined(z.string()),
  amount: MoneySchema,
  vat_rate_id: z.number({ required_error: 'VAT rate is required' }),
  accounting_group_id: z.string().nullish()
})

type Fee = z.infer<typeof FeeSchema>
type PartialFee = Partial<Fee>

/**
 * Partial defaults — initial form state (some undefined)
 * Use for: New entity forms where required validation should trigger
 */
const DEFAULT_FEE_NEW = (): PartialFee => ({
  name: undefined,
  amount: DEFAULT_NEW_MONEY(),
  vat_rate_id: undefined,
  accounting_group_id: null
})

/**
 * Complete defaults — useFormAgent base (all defined)
 * Use for: Form agent initialization
 */
const DEFAULT_FEE = (): Fee => ({
  id: undefined,
  name: '',
  amount: DEFAULT_NEW_MONEY(),
  vat_rate_id: 0,
  accounting_group_id: null
})

/**
 * Model → Form transform (edit mode)
 * Use for: Populating form from existing entity
 */
const feeToFormData = (fee: FeeModel): PartialFee => ({
  id: fee.id,
  name: fee.name,
  amount: fee.amount,
  vat_rate_id: fee.vat_rate.id,  // Nested → flat
  accounting_group_id: fee.accounting_group_id
})

export { FeeSchema, DEFAULT_FEE_NEW, DEFAULT_FEE, feeToFormData }
export type { Fee, PartialFee }
```

---

## Common Scenarios

### Spread Override
**Why?** Customize defaults without mutation.

```typescript
const DEFAULT_NEW_INVOICE = (
  params?: Partial<CreateInvoiceRequest>
): CreateInvoiceRequest => ({
  location_id: 0,
  invoice_date: getTodayYmd(),
  due_date: '',
  sub_total: zero(DEFAULT_CURRENCY),
  tax_total: zero(DEFAULT_CURRENCY),
  total: zero(DEFAULT_CURRENCY),
  line_items: [],
  ...params  // Override any defaults
})

// Usage
const invoice = DEFAULT_NEW_INVOICE({ location_id: 5 })
```

### Frontend-Only Fields
**Why?** Track UI state without polluting API.

```typescript
interface InvoiceLineItemRequest {
  orderable_id: number
  orderable_type: string
  quantity: number
  unit_price: Money

  /** Frontend-only: tracking in v-for */
  _tempId?: string
}

const DEFAULT_LINE_ITEM = (): InvoiceLineItemRequest & { _tempId: string } => ({
  orderable_id: 0,
  orderable_type: '',
  quantity: 1,
  unit_price: zero(DEFAULT_CURRENCY),
  _tempId: generateComplexId()  // Always fresh
})
```
