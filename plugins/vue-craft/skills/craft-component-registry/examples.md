# Component Registry: Examples

---

## Type Config Map

```typescript
const ITEM_TYPE_CONFIG: Record<ItemType, ItemTypeConfig> = {
  [ITEM_KEYS.VARIANT]: {
    component: LazyProductSummary,
    propsBuilder: (value, notes) => ({ product: value, notes })
  },
  [ITEM_KEYS.FEE]: {
    component: LazyFeeSummary,
    propsBuilder: (value, notes) => ({ fee: value, notes })
  }
}
```

---

## Computed Dispatch

```typescript
const component = computed(() => ITEM_TYPE_CONFIG[props.item.type]?.component)

const componentProps = computed(() =>
  ITEM_TYPE_CONFIG[props.item.type]?.propsBuilder(props.item.value, props.item.notes) ?? {}
)
```

---

## Template

```vue
<template>
  <component :is="component" v-bind="componentProps" />
</template>
```

---

## Types

```typescript
interface ItemTypeConfig {
  component: Component | null
  propsBuilder: (value: unknown, notes: string | null) => Record<string, unknown>
}
```
