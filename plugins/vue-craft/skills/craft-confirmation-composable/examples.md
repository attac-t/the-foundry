# Confirmation Composable: Examples

---

## Promise-Based Confirmation

```typescript
const useCreditLimitConfirmation = (options: ConfirmationOptions) => {
  const { creditCheck } = options

  const isDialogVisible = ref(false)
  let resolvePromise: ((value: boolean) => void) | null = null

  const requiresConfirmation = computed(() =>
    creditCheck.value !== null && creditCheck.value.tier >= 2
  )

  const requestConfirmation = (): Promise<boolean> => {
    return new Promise(resolve => {
      resolvePromise = resolve
      isDialogVisible.value = true
    })
  }

  const handleConfirm = () => {
    isDialogVisible.value = false
    resolvePromise?.(true)
    resolvePromise = null
  }

  const handleCancel = () => {
    isDialogVisible.value = false
    resolvePromise?.(false)
    resolvePromise = null
  }

  return { isDialogVisible, requiresConfirmation, requestConfirmation, handleConfirm, handleCancel }
}
```

---

## Usage

```typescript
const handleSave = async () => {
  if (creditConfirmation.requiresConfirmation.value) {
    const confirmed = await creditConfirmation.requestConfirmation()
    if (!confirmed) return
  }
  await saveInvoice()
}
```

---

## Threshold Watching

```typescript
const useCreditLimitConfirmation = (options: ConfirmationOptions) => {
  const wasOverLimitAtStart = ref<boolean | null>(null)
  let stopWatch: (() => void) | null = null

  const startThresholdWatch = () => {
    wasOverLimitAtStart.value = requiresConfirmation.value

    stopWatch = watch(requiresConfirmation, (isNow, was) => {
      // Only trigger if user's action caused the transition
      if (isNow && !was && wasOverLimitAtStart.value === false) {
        isDialogVisible.value = true
      }
    })
  }

  onScopeDispose(() => stopWatch?.())

  return { startThresholdWatch, /* ... */ }
}
```
