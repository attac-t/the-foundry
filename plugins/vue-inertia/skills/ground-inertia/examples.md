# Examples: Inertia Philosophy

## Good: Form as Source

```typescript
// useFormAgent syncs state to form
const { state, form } = useFormAgent(props.invoice, defaultInvoice)

// state changes -> form updates automatically
state.value.total = 100
```

## Bad: Parallel State

```typescript
// Anti-pattern: state lives outside form
const invoice = ref(props.invoice)
const form = useForm(props.invoice)

// Now you have two sources of truth
// They will drift
```

## Good: Dual Variants

```typescript
// Need page reload after save? Inertia variant.
updateDraft(params, form)

// Need to chain save + issue? API variant.
await updateDraftApi(params, form.data())
await issueDraftApi(params)
router.reload()
```

## Good: Router Navigation

```typescript
// Navigation
router.get(route('invoices.index'))

// State-changing action
router.post(route('invoices.issue', { invoice: id }), {})

// Deletion with redirect
router.delete(route('invoices.destroy', { invoice: id }), {
  onSuccess: () => router.visit(route('invoices.index'))
})

// Partial reload
router.reload({ only: ['invoice'] })
```
