# Examples: Inertia vs API

---

## Inertia: Simple Create

```typescript
// Page will redirect to show page after create
const { createDraft } = useCreateInvoice()

createDraft(form, {
  onSuccess: () => {
    // Inertia handles redirect
  }
})
```

---

## Inertia: Simple Update

```typescript
// Page reloads with fresh data
const { updateDraft } = useUpdateInvoice()

updateDraft(params, form, {
  onSuccess: () => {
    // Page already reloaded
  }
})
```

---

## API: Save Then Issue

```typescript
// Need to chain: save draft, then issue, then show result
const { updateDraftApi } = useUpdateInvoice()
const { issueDraftApi } = useIssueInvoice()

const saveAndIssue = async () => {
  const saved = await updateDraftApi(params, form.data())
  if (!saved) return

  const issued = await issueDraftApi(params)
  if (!issued) return

  // Now reload to show issued state
  router.reload()
}
```

---

## API: Conditional Flow

```typescript
// Validate remotely before proceeding
const { validateApi } = useValidateInvoice()

const submitIfValid = async () => {
  const isValid = await validateApi(params, form.data())

  if (!isValid) {
    showErrors()
    return
  }

  form.post(route('invoices.store'))
}
```

---

## Mixed: API Check, Inertia Action

```typescript
// Check if can proceed, then do Inertia action
const canIssue = await checkCanIssueApi(params)

if (!canIssue) {
  showBlockingErrors()
  return
}

router.post(route('invoices.issue', { invoice: id }))
```

---

## Decision Tree

```
Operation complete in one step?
├── Yes → Inertia variant
│         └── Page reloads automatically
└── No → Need to chain?
         ├── Yes → API variant
         │         └── await each step
         │         └── router.reload() at end
         └── No → Conditional logic?
                  ├── Yes → API for check
                  │         └── Inertia for action
                  └── No → Inertia variant
```

---

## Quick Reference

```
Simple CRUD          → Inertia (form.post/put/delete)
Save + another op    → API variant + router.reload()
Validation before    → API check + Inertia action
Multiple sequential  → API variants + router.reload()
```

---

## Anti-Pattern: Mixing Unnecessarily

```typescript
// Bad: Using API when Inertia is simpler
const result = await api.create(data)
if (result) router.visit('/invoices/' + result.id)

// Good: Let Inertia handle redirect
form.post(route('invoices.store'))
```
