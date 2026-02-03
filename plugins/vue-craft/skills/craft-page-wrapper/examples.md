# Page Wrapper: Examples

---

## Template: Thin Wrapper

```vue
<template>
  <EntityScaffold :title="pageTitle">
    <TwnInvoiceActionButtons @save="handleSave" />
    <TwnInvoiceForm v-model="formAgent.state.value" />
    <LazyTwnCreditLimitConfirmation v-model:visible="creditConfirmation.isDialogVisible.value" />
  </EntityScaffold>
</template>
```

---

## Script: Composables Do the Work

```typescript
<script setup>
const formAgent = useFormAgent<CreateInvoiceRequest>({}, DEFAULT_NEW_INVOICE())
const zodRootCtx = useZodValidationRegistry()
const creditConfirmation = useCreditLimitConfirmation({ ... })

const handleSave = async () => {
  await zodRootCtx.validateAll()
  if (zodRootCtx.isAnyInvalid) return showValidationError()
  await createInvoice.create(formAgent.state.value)
}
</script>
```

---

## Clone Flow

```typescript
const invoiceStore = useInvoiceStore()
const isCloning = ref(invoiceStore.hasClonedInvoice)

onMounted(() => {
  const clonedData = invoiceStore.consumeClonedInvoice()
  if (clonedData) formAgent.state.value = clonedData
})
```
