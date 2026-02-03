# Examples: DataTable

---

## Directory Structure

```
components/molecules/prime/table/
└── twn-data-table/
    ├── TwnDataTable.vue
    └── TwnDataTable.types.ts
```

---

## Basic Usage

```vue
<template>
  <TwnDataTable
    v-model:selection="selectedInvoices"
    v-model:first="pagination.first"
    v-model:rows="pagination.rows"
    :value="invoices"
    :columns="columns"
    title="Invoices"
  >
    <template #status="{ data }">
      <TwnTag :severity="getStatusSeverity(data.status)">
        {{ data.status }}
      </TwnTag>
    </template>
  </TwnDataTable>
</template>
```

---

## Column Configuration

```typescript
const columns = [
  { field: 'number', header: 'Invoice #', sortable: true },
  { field: 'customer.name', header: 'Customer', sortable: true },
  { field: 'total', header: 'Total', sortable: true },
  { field: 'status', header: 'Status' },
  TWN_DATA_TABLE_COL_PRESETS.VIEW,
  TWN_DATA_TABLE_COL_PRESETS.FROZEN_ACTIONS
]
```

---

## Column Presets

```typescript
// Import and use presets for common columns
import { TWN_DATA_TABLE_COL_PRESETS } from '@/components/molecules/prime/table/twn-data-table'

const columns = [
  // ... data columns
  TWN_DATA_TABLE_COL_PRESETS.VIEW,           // w-10, frozen right
  TWN_DATA_TABLE_COL_PRESETS.EXPORT,         // w-10, frozen right
  TWN_DATA_TABLE_COL_PRESETS.FROZEN_ACTIONS, // w-16, frozen right
  TWN_DATA_TABLE_COL_PRESETS.FROZEN_ACTIONS_WIDE // w-24, frozen right
]
```

---

## Multiple State Bindings

```vue
<TwnDataTable
  v-model:first="first"
  v-model:rows="rows"
  v-model:sortField="sortField"
  v-model:sortOrder="sortOrder"
  v-model:selection="selection"
  v-model:filters="filters"
  v-model:expandedRows="expandedRows"
  v-model:editingRows="editingRows"
  :value="data"
  :columns="columns"
/>
```

---

## Slot Forwarding Implementation

```vue
<template>
  <DataTable v-bind="$attrs">
    <!-- Column-specific slots (match by field) -->
    <Column v-for="col in columns" :key="col.field" v-bind="col">
      <template v-if="hasSlot(col.field)" #body="slotProps">
        <slot :name="col.field" v-bind="slotProps" />
      </template>
    </Column>

    <!-- Forward all other slots -->
    <template v-for="(_, slotName) in nonColumnSlots" #[slotName]="slotProps">
      <slot :name="slotName" v-bind="slotProps" />
    </template>

    <!-- Empty state -->
    <template #empty>
      <LazyTwnInfoState variant="featured" />
    </template>
  </DataTable>
</template>
```

---

## hasSlot Utility

```typescript
import { useSlots } from 'vue'

const slots = useSlots()

const hasSlot = (name: string) => !!slots[name]
```

---

## Type Definitions

```typescript
interface TwnDataTableProps<T> {
  value: T[]
  columns: ColumnConfig[]
  title?: string
  selectionMode?: 'single' | 'multiple'
  rowsPerPageOptions?: number[]
  lazy?: boolean
  totalRecords?: number
}

interface ColumnConfig {
  field: string | ((row: T) => unknown)
  header?: string
  sortable?: boolean
  frozen?: boolean
  alignFrozen?: 'left' | 'right'
  class?: string
}
```
