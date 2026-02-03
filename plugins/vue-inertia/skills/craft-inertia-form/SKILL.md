# Skill: Craft Inertia Form

> "Form owns state. Callbacks own side effects."

## The Pattern

`useForm` handles form state, validation errors, and submission.

```typescript
import { useForm } from '@inertiajs/vue3'

const form = useForm({
  name: '',
  email: '',
  items: []
})

form.post(route('users.store'), {
  onSuccess: () => { /* redirect or notify */ },
  onError: () => { /* show validation errors */ },
  onFinish: () => { /* always runs */ }
})
```

## The Properties

| Property            | Type      | Description                        |
|---------------------|-----------|------------------------------------|
| `form.data()`       | `T`       | Current form data                  |
| `form.errors`       | `object`  | Validation errors by field         |
| `form.processing`   | `boolean` | Request in progress                |
| `form.isDirty`      | `boolean` | Data changed since last reset      |
| `form.wasSuccessful`| `boolean` | Last request succeeded             |

## The Methods

| Method              | Description                              |
|---------------------|------------------------------------------|
| `form.post(url)`    | Submit via POST                          |
| `form.put(url)`     | Submit via PUT                           |
| `form.delete(url)`  | Submit via DELETE                        |
| `form.reset()`      | Reset to initial values                  |
| `form.defaults()`   | Set new defaults                         |
| `form.clearErrors()`| Clear validation errors                  |

## The Rules

1. **Form owns truth**: Don't duplicate state outside form
2. **Use processing for UI**: Disable buttons, show spinners
3. **Errors are reactive**: Bind directly to template
4. **Reset after submit**: `form.reset()` or let redirect handle it
