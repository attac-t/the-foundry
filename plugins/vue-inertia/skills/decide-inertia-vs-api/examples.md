# Examples: Inertia vs API

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

## API: Conditional Flow

```typescript
// Validate remotely before proceeding
const { validateApi } = useValidateInvoice()

const submitIfValid = async () => {
  const isValid = await validateApi(params, form.data())

  if (isValid) {
    // Now use Inertia for the actual submit
    form.post(route('invoices.store'))
  } else {
    // Show validation errors, don't submit
    showErrors()
  }
}
```

## Mixed: API Check, Inertia Action

```typescript
// Check if can proceed, then do Inertia action
const canIssue = await checkCanIssueApi(params)

if (canIssue) {
  // Simple action - use Inertia
  router.post(route('invoices.issue', { invoice: id }))
} else {
  showBlockingErrors()
}
```

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
