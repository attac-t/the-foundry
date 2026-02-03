# Examples: Dialog

---

## Directory Structure

```
components/
├── atoms/prime/dialog/app-dialog/
│   └── AppDialog.vue
└── molecules/modals/
    ├── modal/Modal.vue
    └── confirmation-modal/ConfirmationModal.vue
```

---

## AppDialog Basic Usage

```vue
<template>
  <AppDialog v-model:visible="showDialog" :style="{ width: '450px' }">
    <template #header>
      Edit Invoice
    </template>

    <InputTextGroup v-model="form.name" label="Name" name="name" />

    <template #footer>
      <Button label="Cancel" severity="secondary" @click="showDialog = false" />
      <Button label="Save" @click="save" />
    </template>
  </AppDialog>
</template>

<script setup lang="ts">
const showDialog = ref(false)
</script>
```

---

## ConfirmationModal

```vue
<template>
  <ConfirmationModal
    :show="showConfirm"
    title="Delete Invoice"
    content="Are you sure you want to delete this invoice? This cannot be undone."
    submit-label="Delete"
    submit-style="danger"
    :processing="isDeleting"
    @close="showConfirm = false"
    @submit="handleDelete"
  />
</template>
```

---

## ConfirmationModal with Custom Content

```vue
<ConfirmationModal
  :show="showConfirm"
  @close="showConfirm = false"
  @submit="handleSubmit"
>
  <template #title>
    <span class="text-red-500">Warning</span>
  </template>

  <template #content>
    <p>This will affect {{ count }} items:</p>
    <ul class="list-disc ml-4 mt-2">
      <li v-for="item in items" :key="item.id">{{ item.name }}</li>
    </ul>
  </template>
</ConfirmationModal>
```

---

## AppDialog Implementation

```vue
<template>
  <Dialog
    :visible="visible"
    @update:visible="emit('update:visible', $event)"
    :modal="modal"
    :closable="closable"
    :draggable="draggable"
    :dismissableMask="dismissableMask"
    v-bind="$attrs"
  >
    <template v-if="$slots.header" #header>
      <slot name="header" />
    </template>

    <slot />

    <template v-if="$slots.footer" #footer>
      <slot name="footer" />
    </template>
  </Dialog>
</template>
```

---

## Modal Component (Custom)

```vue
<template>
  <Teleport to="body">
    <Transition name="modal">
      <div v-if="show" class="fixed inset-0 z-50">
        <!-- Backdrop -->
        <div
          class="absolute inset-0 bg-gray-500 opacity-75"
          @click="closeable && emit('close')"
        />

        <!-- Content -->
        <div :class="['relative', maxWidthClass]">
          <slot />
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
// Escape key closes modal
onMounted(() => {
  document.addEventListener('keydown', handleEscape)
})

const handleEscape = (e: KeyboardEvent) => {
  if (e.key === 'Escape' && props.closeable) {
    emit('close')
  }
}
</script>
```

---

## Processing State

```vue
<template>
  <ConfirmationModal :processing="isProcessing" @submit="handleSubmit">
    <!-- Submit button automatically disabled and dimmed -->
  </ConfirmationModal>
</template>

<script setup lang="ts">
const isProcessing = ref(false)

const handleSubmit = async () => {
  isProcessing.value = true
  await doWork()
  isProcessing.value = false
  emit('close')
}
</script>
```
