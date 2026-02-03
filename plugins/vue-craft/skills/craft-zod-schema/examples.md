# Zod Schema: Examples

---

## Basic Schema

```typescript
import { z } from 'zod'
import { preprocessEmptyAsUndefined, preprocessZeroAsUndefined } from '@/composables/use-zod'

const FeeSchema = z.object({
  id: z.number().nullish(),
  name: preprocessEmptyAsUndefined(z.string()),
  amount: MoneySchema,
  vat_rate_id: z.number({ required_error: 'VAT rate is required' }),
  accounting_group_id: z.string().nullish()
})

type Fee = z.infer<typeof FeeSchema>

export { FeeSchema }
export type { Fee }
```

---

## Cross-Field Validation

```typescript
const InvoiceInformationSchema = z
  .object({
    location_id: preprocessZeroAsUndefined(z.number({ required_error: 'Location is required' })),
    user_id: preprocessEmptyAsUndefined(z.string().optional().nullable()),
    company_id: preprocessEmptyAsUndefined(z.string().optional().nullable())
  })
  .refine(
    data => !!data.user_id || !!data.company_id,
    { message: 'Either customer or company is required', path: ['user_id'] }
  )
  .refine(
    data => !(data.user_id && data.company_id),
    { message: 'Cannot select both customer and company', path: ['user_id'] }
  )
```

---

## Conditional Required

```typescript
const PaymentSchema = z
  .object({
    payment_method: z.enum(['card', 'bank_transfer', 'cash']),
    card_number: z.string().optional(),
    bank_account: z.string().optional()
  })
  .refine(
    data => data.payment_method !== 'card' || !!data.card_number,
    { message: 'Card number required', path: ['card_number'] }
  )
  .refine(
    data => data.payment_method !== 'bank_transfer' || !!data.bank_account,
    { message: 'Bank account required', path: ['bank_account'] }
  )
```

---

## File Organization

```
domains/{domain}/validations/ui/{entity}Validation.schema.ts
```

```typescript
// invoiceValidation.schema.ts
const InvoiceInformationSchema = z.object({ ... })
const InvoiceLineItemSchema = z.object({ ... })

export { InvoiceInformationSchema, InvoiceLineItemSchema }
```
