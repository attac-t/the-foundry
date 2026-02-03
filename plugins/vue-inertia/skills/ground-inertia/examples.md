# Examples: Inertia Philosophy

---

## Good: Form as Source

```typescript
// useFormAgent syncs state to form
const { state, form } = useFormAgent(props.invoice, defaultInvoice)

// state changes -> form updates automatically
state.value.total = 100

// Form is always in sync
form.post(route('invoices.store'))
```

---

## Bad: Parallel State

```typescript
// Anti-pattern: state lives outside form
const invoice = ref(props.invoice)
const form = useForm(props.invoice)

// Now you have two sources of truth
// They will drift
```

---

## Good: Dual Variants

```typescript
// Need page reload after save? Inertia variant.
updateDraft(params, form)

// Need to chain save + issue? API variant.
await updateDraftApi(params, form.data())
await issueDraftApi(params)
router.reload()
```

---

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

---

## Good: Single Toast Per Operation

```typescript
const notification = useEntityNotification({
  action: 'Creating',
  entityName: 'invoice'
})

notification.startOperation()  // Toast: "Creating invoice..."

// Same toast updates in-place:
notification.onSuccess()       // Toast: "Invoice created successfully"
// OR
notification.onError()         // Toast: "Failed to create invoice"
```

---

## Bad: Multiple Toasts

```typescript
// Anti-pattern: separate toasts for each state
toast.info('Creating invoice...')
// ...later...
toast.success('Invoice created!')  // Now there are 2 toasts

// Do this instead: reuse same toast ID
```

---

## Good: Trust Defaults

```typescript
// Don't over-specify
form.post(route('invoices.store'))

// Not this (unnecessary):
form.post(route('invoices.store'), {
  preserveState: true,
  preserveScroll: true
})
```
