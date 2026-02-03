# Validation Location: Examples

UI vs API validation concerns.

---

## UI: Required Field

**Why?** Immediate feedback. Don't wait for server.

```typescript
// Zod schema for UI
const InvoiceSchema = z.object({
  location_id: preprocessZeroAsUndefined(
    z.number({ required_error: 'Location is required' })
  )
})

// User sees error immediately on blur
```

---

## API: Business Rule

**Why?** Security. Can't trust client.

```php
// Laravel Form Request
public function rules(): array
{
    return [
        'location_id' => ['required', 'exists:locations,id'],
        'total' => ['required', 'numeric', 'min:0'],
    ];
}
```

---

## UI: Cross-Field Validation

**Why?** Guide user to correct combination.

```typescript
const InvoiceInfoSchema = z.object({
  user_id: z.string().optional(),
  company_id: z.number().optional()
}).refine(
  data => !!data.user_id || !!data.company_id,
  { message: 'Either customer or company is required', path: ['user_id'] }
).refine(
  data => !(data.user_id && data.company_id),
  { message: 'Cannot have both customer and company', path: ['user_id'] }
)
```

---

## API: Authorization

**Why?** Security. Must verify on server.

```php
// Only API can verify user has access to this location
public function authorize(): bool
{
    return $this->user()->can('create', [
        Invoice::class,
        $this->location_id
    ]);
}
```

---

## The Overlap

| Validation             | UI           | API        |
|------------------------|:------------:|:----------:|
| Required fields        | ✅           | ✅         |
| Format (email, phone)  | ✅           | ✅         |
| Business rules         | ⚠️ Hint only | ✅ Enforce |
| Authorization          | ❌           | ✅         |
| Uniqueness             | ❌           | ✅         |

**Key:** UI can duplicate API rules for UX. API can't skip any rule for security.
