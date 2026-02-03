# Examples: Autocomplete Group

---

## Directory Structure

```
components/molecules/prime/form/
└── input-autocomplete-group/
    ├── InputAutocompleteGroup.vue
    └── InputAutocompleteGroup.types.ts
```

---

## Basic Usage

```vue
<template>
  <InputAutocompleteGroup
    v-model="form.product"
    :options="products"
    option-label="name"
    label="Product"
    name="product"
  />
</template>
```

---

## Dual Search Fields

```vue
<template>
  <InputAutocompleteGroup
    v-model="form.product"
    :options="productsWithSearchable"
    option-label="name"
    label="Product"
    name="product"
  />
</template>

<script setup lang="ts">
// Products with searchableText for SKU/barcode search
const productsWithSearchable = computed(() =>
  products.value.map(p => ({
    ...p,
    searchableText: `${p.sku} ${p.barcode}`
  }))
)
</script>
```

---

## Search Implementation

```typescript
const filteredOptions = ref<Option[]>([])

const search = (event: AutoCompleteCompleteEvent) => {
  const query = event.query.toLowerCase()

  if (!query) {
    // CRITICAL: Spread required to trigger PrimeVue's suggestions watcher
    filteredOptions.value = [...props.options]
    return
  }

  filteredOptions.value = props.options.filter(option => {
    // Search primary label
    const labelMatch = String(option[props.optionLabel])
      .toLowerCase()
      .includes(query)

    // Search additional field (SKU, barcode, etc.)
    const searchableMatch = option.searchableText
      ?.toLowerCase()
      .includes(query)

    return labelMatch || searchableMatch
  })
}

// Re-filter when options change (async API results)
watch(() => props.options, () => {
  if (props.options.length > 0) {
    filteredOptions.value = [...props.options]
  }
})
```

---

## Fluid Width Workaround

```vue
<template>
  <InputLabelMessageGroup v-bind="labelProps">
    <AutoComplete
      :suggestions="filteredOptions"
      @complete="search"
      fluid
    />
  </InputLabelMessageGroup>
</template>

<style scoped>
/* PrimeVue v4.3.4+ bug: fluid doesn't apply width: 100% */
:deep(.p-autocomplete-fluid) {
  width: 100%;
}
</style>
```

---

## With Custom Item Template

```vue
<InputAutocompleteGroup
  v-model="form.product"
  :options="products"
  option-label="name"
  label="Product"
  name="product"
>
  <template #option="{ option }">
    <div class="flex items-center gap-2">
      <img :src="option.image" class="w-8 h-8 rounded" />
      <div>
        <div class="font-medium">{{ option.name }}</div>
        <div class="text-sm text-gray-500">SKU: {{ option.sku }}</div>
      </div>
    </div>
  </template>
</InputAutocompleteGroup>
```

---

## Type Definitions

```typescript
interface InputAutocompleteGroupProps {
  modelValue: unknown
  options: Option[]
  optionLabel: string

  // Optional searchable field for dual search
  // e.g., SKU, barcode, alternative name

  // Form group props
  label?: string
  name: string
  placeholder?: string
  message?: string
  state?: boolean | null
  labelType?: 'float' | 'ifta'
  disabled?: boolean
  fluid?: boolean
}

interface Option {
  [key: string]: unknown
  searchableText?: string  // Additional searchable content
}
```

---

## Async Options

```vue
<template>
  <InputAutocompleteGroup
    v-model="form.customer"
    :options="customers"
    option-label="name"
    label="Customer"
    name="customer"
  />
</template>

<script setup lang="ts">
const customers = ref<Customer[]>([])

onMounted(async () => {
  // Options load async - component re-filters automatically
  customers.value = await fetchCustomers()
})
</script>
```
