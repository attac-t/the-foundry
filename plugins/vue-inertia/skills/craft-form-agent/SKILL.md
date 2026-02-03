# Skill: Craft Form Agent

> "State and form, always in sync."

## The Pattern

`useFormAgent` bridges reactive state and Inertia forms.

```typescript
const useFormAgent = <T>(initial: Partial<T>, defaults: T) => {
  const merged = merge({}, defaults, initial)
  const state = ref<T>(merged)
  const form = useForm(merged)

  watch(state, (newState) => {
    const data = { ...form.data(), ...newState }
    data['slug'] = undefined  // Strip prohibited keys
    form.defaults(data).reset()
  }, { deep: true })

  return { state, form }
}
```

## The Structure

```typescript
// Returns tuple: reactive state + Inertia form
const { state, form } = useFormAgent(props.invoice, defaultInvoice)

// Mutate state - form stays in sync
state.value.name = 'New Name'

// Submit form - state values flow through
form.post(route('invoices.store'))
```

## The Rules

1. **Merge order**: `defaults` first, then `initial` (partial overwrites)
2. **Strip prohibited keys**: `slug` stripped before submission
3. **Deep watch**: Nested object changes trigger sync
4. **Array handling**: Arrays clone, don't merge (avoids object corruption)

## The Anti-Patterns

| Don't                            | Do                            |
|----------------------------------|-------------------------------|
| Mutate form directly             | Mutate state, let sync happen |
| Create separate form and state   | Use `useFormAgent` tuple      |
| Include slug in submissions      | Let agent strip it            |
| Shallow watch                    | Agent uses deep watch         |
