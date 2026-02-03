# Zod Registry: Examples

---

## Parent: Create Registry

```typescript
const zodRootCtx = useZodValidationRegistry()

const handleSave = async () => {
  await zodRootCtx.validateAll()
  if (zodRootCtx.isAnyInvalid) return showValidationError()
  submitForm()
}
```

---

## Child: Register Validation

```typescript
const zodCtx = useRegisteredZodValidation(
  'fee-form',      // Unique name
  FeeSchema,       // Zod schema
  modelValue,      // Data to validate
  { mode: 'lazy' } // Validate on blur
)

// In template
<InputTextGroup
  :message="zodCtx.getInvalidFeedback('name')"
  :state="zodCtx.getState('name')"
/>
```

---

## Registry API

```typescript
// Aggregate state
zodRootCtx.isAllValid
zodRootCtx.isAnyInvalid
zodRootCtx.isAnyDirty

// Aggregate operations
await zodRootCtx.validateAll()
zodRootCtx.resetAll()
zodRootCtx.touchAll()
```
