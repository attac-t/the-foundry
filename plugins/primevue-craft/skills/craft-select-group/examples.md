# Examples: Select Group

---

## Directory Structure

```
components/molecules/prime/form/
└── input-select-group/
    ├── InputSelectGroup.vue
    └── InputSelectGroup.types.ts
```

---

## Basic Usage

```vue
<template>
  <InputSelectGroup
    v-model="form.status"
    :options="statusOptions"
    option-label="label"
    option-value="value"
    label="Status"
    name="status"
  />
</template>

<script setup lang="ts">
const statusOptions = [
  { label: 'Draft', value: 'draft' },
  { label: 'Sent', value: 'sent' },
  { label: 'Paid', value: 'paid' }
]
</script>
```

---

## With Add Button

```vue
<template>
  <InputSelectGroup
    v-model="form.customer_id"
    :options="customers"
    option-label="name"
    option-value="id"
    label="Customer"
    name="customer"
    allow-add
    @add="showAddCustomerModal = true"
  />

  <AddCustomerModal
    v-model:visible="showAddCustomerModal"
    @created="handleCustomerCreated"
  />
</template>
```

---

## Slot Forwarding Implementation

```vue
<template>
  <InputLabelMessageGroup v-bind="labelProps">
    <Select
      :model-value="modelValue"
      @update:model-value="emit('update:modelValue', $event)"
      :options="options"
      :option-label="optionLabel"
      :option-value="optionValue"
      :option-disabled="optionDisabled"
      :invalid="state === false"
      :placeholder="placeholderProxy"
      :disabled="disabled"
      :loading="loading"
      :show-clear="showClear"
      :fluid="fluid"
      @change="emit('change', $event.value)"
    >
      <!-- Forward all slots -->
      <template v-for="(_, slotName) in $slots" #[slotName]="slotProps">
        <slot :name="slotName" v-bind="slotProps" />
      </template>

      <!-- Footer with add button -->
      <template #footer>
        <slot name="footer">
          <TwnAddBtn v-if="allowAdd" @click="emit('add')" />
        </slot>
      </template>
    </Select>
  </InputLabelMessageGroup>
</template>
```

---

## Type Definitions

```typescript
interface InputSelectGroupProps {
  modelValue: unknown
  options: unknown[]
  optionLabel?: string
  optionValue?: string
  optionDisabled?: string

  // Form group props
  label?: string
  name: string
  placeholder?: string
  message?: string
  state?: boolean | null
  labelType?: 'float' | 'ifta'
  inline?: boolean
  labelClass?: string

  // Select-specific
  allowAdd?: boolean
  disabled?: boolean
  loading?: boolean
  showClear?: boolean
  fluid?: boolean
  size?: 'small' | 'large'
}

interface InputSelectGroupEmits {
  'update:modelValue': [value: unknown]
  'change': [value: unknown]
  'add': []
}
```

---

## With Custom Option Template

```vue
<InputSelectGroup
  v-model="form.product_id"
  :options="products"
  option-label="name"
  option-value="id"
  label="Product"
  name="product"
>
  <template #option="{ option }">
    <div class="flex items-center gap-2">
      <img :src="option.image" class="w-8 h-8" />
      <div>
        <div>{{ option.name }}</div>
        <div class="text-sm text-gray-500">{{ option.sku }}</div>
      </div>
    </div>
  </template>
</InputSelectGroup>
```

---

## Loading State

```vue
<InputSelectGroup
  v-model="form.category_id"
  :options="categories"
  :loading="isLoadingCategories"
  label="Category"
  name="category"
/>
```
