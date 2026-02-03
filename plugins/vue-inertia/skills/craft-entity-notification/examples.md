# Examples: Entity Notification

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

## With Entity Identifier

```typescript
const notification = useEntityNotification({
  action: 'Updating',
  entityName: `invoice ${displayNumber}`  // "invoice INV-001"
})
```

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

## Toast Messages

```typescript
// Config
{ action: 'Creating', entityName: 'invoice' }

// startOperation
{ severity: 'info', detail: 'Creating invoice...' }

// onSuccess
{ severity: 'success', detail: 'Invoice created successfully' }

// onError
{ severity: 'error', detail: 'Failed to create invoice' }
```

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
