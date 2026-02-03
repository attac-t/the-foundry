# Vue: Examples

---

## ref vs computed

```typescript
// ❌ ref for derived value — won't update
const fullName = ref(`${firstName.value} ${lastName.value}`)

// ✅ computed for derivations
const fullName = computed(() => `${firstName.value} ${lastName.value}`)
```

---

## watch vs computed

```typescript
// ❌ watch to compute a value
const total = ref(0)
watch(items, (newItems) => {
  total.value = newItems.reduce((sum, i) => sum + i.price, 0)
})

// ✅ computed for derived values
const total = computed(() =>
  items.value.reduce((sum, i) => sum + i.price, 0)
)
```

---

## toValue for flexible inputs

```typescript
// ❌ Rigid: only accepts ref
const useCalc = (price: Ref<number>) => { ... }

// ✅ Flexible: accepts ref, getter, or raw value
const useCalc = (price: MaybeRefOrGetter<number>) => {
  const unwrapped = computed(() => toValue(price))
}
```
