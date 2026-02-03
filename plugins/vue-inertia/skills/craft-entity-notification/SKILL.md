# Skill: Craft Entity Notification

> "One operation, one toast, three states."

## The Pattern

`useEntityNotification` manages toast lifecycle for CRUD operations.

```typescript
const useEntityNotification = (config: {
  action: string      // "Creating", "Updating", "Deleting"
  entityName: string  // "invoice", "invoice INV-001"
}) => {
  const operationId = generateId()
  const hasCompleted = ref(false)

  return {
    startOperation,  // Show "Creating invoice..."
    onSuccess,       // Update to "Invoice created successfully"
    onError,         // Update to "Failed to create invoice"
    onFinish         // Catch-all if neither success/error fired
  }
}
```

## The Lifecycle

```
startOperation()  →  Toast appears with "Creating invoice..."
                     ↓
    onSuccess()   →  Same toast updates: "Invoice created successfully"
         OR
    onError()     →  Same toast updates: "Failed to create invoice"
                     ↓
    onFinish()    →  If hasCompleted=false, show error (catch-all)
```

## The Rules

1. **Same toast ID**: All updates target the same notification
2. **hasCompleted flag**: Prevents double error display
3. **onFinish catch-all**: Handles edge cases where callbacks didn't fire
4. **Verb transformation**: "Creating" → "created", "Deleting" → "delete"

## The Anti-Patterns

| Don't                             | Do                                    |
|-----------------------------------|---------------------------------------|
| Show separate success/error toast | Reuse same ID for update-in-place     |
| Skip onFinish                     | Always wire it as catch-all           |
| Manual toast management           | Use notification composable           |
| Forget hasCompleted check         | Pattern handles it                    |
