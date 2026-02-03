# Skill: Craft DataTable

> "Tables with opinions. Columns with presets."

## The Pattern

`TwnDataTable` wraps PrimeVue DataTable with multi-state defineModel and column presets.

```typescript
// Multiple defineModel for each two-way state
const first = defineModel<number>('first', { default: 0 })
const rows = defineModel<number>('rows', { default: 10 })
const sortField = defineModel<string>('sortField')
const sortOrder = defineModel<number>('sortOrder')
const selection = defineModel<T[]>('selection')
const filters = defineModel<DataTableFilterMeta>('filters')
const expandedRows = defineModel<T[]>('expandedRows')
const editingRows = defineModel<T[]>('editingRows')
```

## Column Presets

```typescript
const TWN_DATA_TABLE_COL_PRESETS = {
  VIEW: { field: 'view', frozen: true, alignFrozen: 'right', class: 'w-10' },
  EXPORT: { field: 'export', frozen: true, alignFrozen: 'right', class: 'w-10' },
  FROZEN_ACTIONS: { field: 'actions', frozen: true, alignFrozen: 'right', class: 'w-16' },
  FROZEN_ACTIONS_WIDE: { field: 'actions', frozen: true, alignFrozen: 'right', class: 'w-24' }
}
```

## The Rules

1. **defineModel per state**: Each two-way binding gets its own defineModel
2. **Column presets**: Use presets for common frozen columns
3. **Slot forwarding**: Forward all non-column slots to DataTable
4. **Column slots match field**: Slot name matches column field for overrides
5. **Lazy empty state**: Use LazyTwnInfoState for "no data" with featured variant
6. **Field flexibility**: Handle both string and function field types

## The Anti-Patterns

| Don't                               | Do                                    |
|-------------------------------------|---------------------------------------|
| Manual v-model:selection/etc        | Use TwnDataTable defineModel states   |
| Hardcode frozen column configs      | Use TWN_DATA_TABLE_COL_PRESETS        |
| Inline empty state                  | Lazy load TwnInfoState component      |
| Skip slot forwarding                | Forward all $slots to DataTable       |
