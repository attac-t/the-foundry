# Filter Composable: Examples

Filter patterns from production code.

---

## The Pattern

### Type-Switched Query
**Why?** Different types need different filters.

```typescript
const MORPH_TYPES = {
  USER: 'user',
  LOCATION: 'location',
  DAY: 'day',
  WEEK: 'week'
} as const

type MorphType = (typeof MORPH_TYPES)[keyof typeof MORPH_TYPES]

interface FilterModel {
  type: MorphType
  value: User | Location | string  // Depends on type
}

const useWorkSessionFilters = (model: Ref<FilterModel>) => {
  const getFilteredBaseQuery = () => ({
    per_page: 50,
    sort: '-started_at'
  })

  const filters = computed(() => {
    const result: Record<string, unknown> = getFilteredBaseQuery()

    switch (model.value.type) {
      case MORPH_TYPES.USER:
        result.user_id = (model.value.value as User).id
        break

      case MORPH_TYPES.LOCATION:
        result.location_id = (model.value.value as Location).id
        break

      case MORPH_TYPES.DAY: {
        const date = DateTime.fromISO(model.value.value as string)
        result.started_at = date.startOf('day').toISO()
        result.ended_at = date.endOf('day').toISO()
        break
      }

      case MORPH_TYPES.WEEK: {
        const date = DateTime.fromISO(model.value.value as string)
        result.started_at = date.startOf('week').toISO()
        result.ended_at = date.endOf('week').toISO()
        break
      }
    }

    return result
  })

  return { filters }
}
```

---

## Common Scenarios

### Base Query Helper
**Why?** Common filters shared across types.

```typescript
const getFilteredBaseQuery = () => ({
  per_page: 50,
  sort: '-created_at',
  include: ['user', 'location']
})
```

### Usage with API
**Why?** Reactive filters drive API calls.

```typescript
const { filters } = useWorkSessionFilters(model)

// Filters update automatically when model changes
const { data, refresh } = useAsyncData(() =>
  api.index({ params: filters.value })
)

// Watch filters to refresh
watch(filters, () => refresh())
```
