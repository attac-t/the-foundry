# Examples: DataTable

---

## Directory Structure

```
components/molecules/prime/table/
└── app-data-table/
    ├── AppDataTable.vue
    └── AppDataTable.types.ts
```

---

## Basic Usage

```vue
<template>
  <AppDataTable
    v-model:selection="selectedInvoices"
    v-model:first="pagination.first"
    v-model:rows="pagination.rows"
    :value="invoices"
    :columns="columns"
    title="Invoices"
  >
    <template #status="{ data }">
      <AppTag :severity="getStatusSeverity(data.status)">
        {{ data.status }}
      </AppTag>
    </template>
  </AppDataTable>
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
  DATA_TABLE_COL_PRESETS.VIEW,
  DATA_TABLE_COL_PRESETS.FROZEN_ACTIONS
]
```

---

## Column Presets

```typescript
// Import and use presets for common columns
import { DATA_TABLE_COL_PRESETS } from '@/components/molecules/prime/table/app-data-table'

const columns = [
  // ... data columns
  DATA_TABLE_COL_PRESETS.VIEW,           // w-10, frozen right
  DATA_TABLE_COL_PRESETS.EXPORT,         // w-10, frozen right
  DATA_TABLE_COL_PRESETS.FROZEN_ACTIONS, // w-16, frozen right
  DATA_TABLE_COL_PRESETS.FROZEN_ACTIONS_WIDE // w-24, frozen right
]
```

---

## Multiple State Bindings

```vue
<AppDataTable
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
      <LazyInfoState variant="featured" />
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
interface AppDataTableProps<T> {
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
