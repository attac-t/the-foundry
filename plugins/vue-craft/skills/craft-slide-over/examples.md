# Slide-Over: Examples

---

## State Refs

```typescript
const isFormVisible = ref(false)
const isEditMode = ref(false)
const deleteConfirmationFor = ref<string | null>(null)
```

---

## Mutual Exclusion

```typescript
const handleCreateNew = () => {
  isFormVisible.value = true
  isEditMode.value = false
  deleteConfirmationFor.value = null
}

const handleEditAction = (session: Session) => {
  isFormVisible.value = true
  isEditMode.value = true
  deleteConfirmationFor.value = null
}

const handleDeleteAction = (session: Session) => {
  isFormVisible.value = false
  deleteConfirmationFor.value = session.id
}
```

---

## Reset on Close

```typescript
watch(visible, (isVisible) => {
  if (!isVisible) {
    isFormVisible.value = false
    deleteConfirmationFor.value = null
    resetForm()
  }
})
```

---

## Template

```vue
<TwnSlideOver v-model:visible="visible">
  <Transition name="form-slide">
    <TwnInlineForm v-if="isFormVisible" :is-edit-mode="isEditMode" />
  </Transition>

  <ItemList :delete-confirmation-for="deleteConfirmationFor" />
</TwnSlideOver>
```
