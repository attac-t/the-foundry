# Examples: Inertia Form

## Basic Form

```typescript
import { useForm } from '@inertiajs/vue3'

const form = useForm({
  name: '',
  email: '',
  role: 'user'
})

const submit = () => {
  form.post(route('users.store'), {
    onSuccess: () => {
      // Redirect happens via Inertia
    }
  })
}
```

## Template Binding

```vue
<template>
  <form @submit.prevent="submit">
    <input v-model="form.name" />
    <span v-if="form.errors.name">{{ form.errors.name }}</span>

    <input v-model="form.email" />
    <span v-if="form.errors.email">{{ form.errors.email }}</span>

    <button :disabled="form.processing">
      {{ form.processing ? 'Saving...' : 'Save' }}
    </button>
  </form>
</template>
```

## Update Pattern

```typescript
const form = useForm({
  name: props.user.name,
  email: props.user.email
})

const submit = () => {
  form.put(route('users.update', { user: props.user.id }), {
    onSuccess: () => {
      // Page reloads with fresh data
    },
    preserveScroll: true  // Only if needed
  })
}
```

## With useFormAgent

```typescript
// When you need reactive state outside form
const { state, form } = useFormAgent(props.invoice, defaultInvoice)

// Mutate state - form syncs automatically
state.value.total = calculateTotal()

// Submit form
form.post(route('invoices.store'))
```

## Processing State for UI

```typescript
// Disable multiple submissions
<button :disabled="form.processing" />

// Show spinner
<Spinner v-if="form.processing" />

// Conditional text
{{ form.processing ? 'Saving...' : 'Save' }}
```

## Error Handling

```typescript
form.post(route('users.store'), {
  onError: (errors) => {
    // errors is also available as form.errors
    console.log(errors)
    // { email: 'Email already taken' }
  }
})

// Clear specific error
form.clearErrors('email')

// Clear all errors
form.clearErrors()
```
