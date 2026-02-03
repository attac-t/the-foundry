# Examples: PrimeVue Philosophy

---

## Good: Wrapper Over Raw

```vue
<!-- Domain code uses wrapper -->
<TwnDataTable
  v-model:selection="selectedInvoices"
  :value="invoices"
  :columns="columns"
/>

<!-- Not raw PrimeVue -->
<DataTable
  v-model:selection="selectedInvoices"
  :value="invoices"
>
  <!-- Manual column setup... -->
</DataTable>
```

---

## Good: defineModel for Multiple States

```typescript
// TwnDataTable.vue
const first = defineModel<number>('first', { default: 0 })
const rows = defineModel<number>('rows', { default: 10 })
const sortField = defineModel<string>('sortField')
const sortOrder = defineModel<number>('sortOrder')
const selection = defineModel<T[]>('selection')
const filters = defineModel<DataTableFilterMeta>('filters')
const expandedRows = defineModel<T[]>('expandedRows')
const editingRows = defineModel<T[]>('editingRows')

// Each state independently two-way bound
```

---

## Good: Slot Forwarding

```vue
<template>
  <DataTable v-bind="$attrs">
    <!-- Forward all parent slots -->
    <template v-for="(_, slotName) in $slots" #[slotName]="slotProps">
      <slot :name="slotName" v-bind="slotProps" />
    </template>
  </DataTable>
</template>
```

---

## Good: Three-State Validation

```typescript
interface Props {
  state?: boolean | null  // true, false, or null
}

// Convert to PrimeVue's invalid prop
const isInvalid = computed(() => props.state === false)

// Show error message only when invalid
const showError = computed(() => props.state === false && props.message)
```

---

## Good: Unique Field Names

```typescript
import { uniqueId } from 'lodash-es'

const fieldName = computed(() => uniqueId(`${props.name || 'input'}-`))

// Result: "customer-name-1", "customer-name-2", etc.
// Ensures label htmlFor matches input id
```

---

## Bad: Raw PrimeVue in Domain

```vue
<!-- Anti-pattern: inconsistent validation, no slot forwarding -->
<InputText
  v-model="name"
  :class="{ 'p-invalid': hasError }"
/>
<small v-if="hasError" class="p-error">{{ error }}</small>

<!-- Do this: use wrapper -->
<InputTextGroup
  v-model="name"
  :state="validation.name.valid"
  :message="validation.name.message"
/>
```

---

## Good: PT System Merging

```typescript
import { usePrimeVuePtMerge } from '@/composables/use-primevue-pt-merge'

const { mergePt } = usePrimeVuePtMerge()

const ptConfig = mergePt(defaultPt, props.pt)

// Allows user overrides while keeping defaults
```
