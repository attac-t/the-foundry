# Zod Preprocess: Examples

---

## Preprocess Helpers

```typescript
// composables/use-zod/zodHelpers.ts
import { z, type ZodTypeAny } from 'zod'

const emptyAsUndefined = (val: unknown) =>
  val === '' || val === null ? undefined : val

const preprocessEmptyAsUndefined = <T extends ZodTypeAny>(schema: T) =>
  z.preprocess(emptyAsUndefined, schema)

const zeroAsUndefined = (val: unknown) =>
  val === 0 ? undefined : val

const preprocessZeroAsUndefined = <T extends ZodTypeAny>(schema: T) =>
  z.preprocess(zeroAsUndefined, schema)

export { preprocessEmptyAsUndefined, preprocessZeroAsUndefined }
```

---

## Required String

```typescript
// Without preprocess: '' passes z.string()
// With preprocess: '' becomes undefined, fails required

const Schema = z.object({
  name: preprocessEmptyAsUndefined(
    z.string({ required_error: 'Name is required' })
  )
})

// Input: { name: '' } → Result: "Name is required"
```

---

## Required Select

```typescript
const Schema = z.object({
  location_id: preprocessZeroAsUndefined(
    z.number({ required_error: 'Location is required' })
  ),
  vat_rate_id: preprocessZeroAsUndefined(
    z.number({ required_error: 'VAT rate is required' })
  )
})

// Input: { location_id: 0, vat_rate_id: 0 } → Both show required errors
```

---

## Optional Fields

```typescript
const Schema = z.object({
  // Required: needs preprocess
  name: preprocessEmptyAsUndefined(z.string()),

  // Optional: no preprocess needed
  notes: z.string().optional().nullable()
})
```
