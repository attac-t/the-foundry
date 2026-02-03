# Examples: Entity Notification

---

## Directory Structure

```
composables/
└── use-entity-notification/
    ├── useEntityNotification.ts
    └── useEntityNotification.types.ts
```

---

## Basic Usage

```typescript
import { useEntityNotification } from '@/composables/use-entity-notification/useEntityNotification'

const notification = useEntityNotification({
  action: 'Creating',
  entityName: 'invoice'
})

notification.startOperation()

form.post(route('invoices.store'), {
  onSuccess: () => notification.onSuccess(),
  onError: () => notification.onError(),
  onFinish: () => notification.onFinish()
})
```

---

## With Entity Identifier

```typescript
const notification = useEntityNotification({
  action: 'Updating',
  entityName: `invoice ${displayNumber}`  // "invoice INV-001"
})
```

---

## Type Definition

```typescript
interface EntityNotificationConfig {
  action: string      // Present participle: "Creating", "Updating"
  entityName: string  // Entity with optional identifier
}

interface EntityNotificationHandlers {
  startOperation: () => void
  onSuccess: () => void
  onError: () => void
  onFinish: () => void
}
```

---

## Toast Messages

```typescript
// Config
{ action: 'Creating', entityName: 'invoice' }

// startOperation
{ severity: 'info', detail: 'Creating invoice...' }

// onSuccess - capitalize entity, past tense verb
{ severity: 'success', detail: 'Invoice created successfully' }

// onError - base verb form
{ severity: 'error', detail: 'Failed to create invoice' }
```

---

## Verb Transformations

```typescript
// Action verbs follow consistent transformation:
// Present participle → past tense (success)
// Present participle → base verb (error)

'Creating'  → 'created'  / 'create'
'Updating'  → 'updated'  / 'update'
'Deleting'  → 'deleted'  / 'delete'
'Issuing'   → 'issued'   / 'issue'
'Voiding'   → 'voided'   / 'void'
'Saving'    → 'saved'    / 'save'

// These are handled by utility functions:
// toPastTense(action) - for success messages
// toBaseVerb(action)  - for error messages
// capitalize(entity)  - for success messages
```

---

## The onFinish Catch-All

```typescript
// onFinish only shows error if hasCompleted is false
// This catches edge cases like:
// - Network failures where neither callback fired
// - Unexpected form states

const onFinish = () => {
  if (!hasCompleted.value) {
    // Show error - something went wrong silently
    toastStore.add({ severity: 'error', ... })
  }
}
```

---

## Same Toast ID (Update-in-Place)

```typescript
// All operations use the same operationId
// Toast updates in-place instead of spawning new toasts

const operationId = generateComplexId()

startOperation() → toastStore.add({ id: operationId, ... })
onSuccess()      → toastStore.add({ id: operationId, ... })  // Updates same toast
onError()        → toastStore.add({ id: operationId, ... })  // Updates same toast
```
