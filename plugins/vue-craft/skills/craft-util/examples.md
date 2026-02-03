# Util: Examples

---

## Structure

```
utils/money-util/
├── __tests__/moneyUtil.test.ts
├── moneyUtil.ts
└── MoneyUtil.types.ts
```

---

## Named Parameters

```typescript
// ❌ Positional
const add = (m1: Money, m2: Money) => ...

// ✅ Named
const add = ({ money1, money2 }: AddParams): MoneyModel => ...

// Usage
const sum = add({ money1: subtotal, money2: tax })
```

---

## Pure Functions

```typescript
const mergeLineItems = (items: Item[], options = {}): MergeResult => {
  const mergeMap = new Map<string, Item>()
  for (const item of items) {
    const key = createMergeKey(item)
    const existing = mergeMap.get(key)
    mergeMap.set(key, existing ? mergeLineItem(existing, item) : { ...item })
  }
  return { items: [...mergeMap.values()], combinedCount: items.length - mergeMap.size }
}
```

---

## Export Helpers for Testing

```typescript
export { createMergeKey, canMergeLineItems, mergeLineItem, mergeLineItems }
```
