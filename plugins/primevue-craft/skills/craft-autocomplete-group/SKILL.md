# Skill: Craft Autocomplete Group

> "Search two fields. Handle the bugs."

## The Pattern

`InputAutocompleteGroup` wraps PrimeVue AutoComplete with dual search fields and documented workarounds.

```typescript
// Search both label and additional field (SKU, barcode)
const search = (event: AutoCompleteCompleteEvent) => {
  const query = event.query.toLowerCase()

  if (!query) {
    // WORKAROUND: Spread required to trigger PrimeVue watcher
    filteredOptions.value = [...props.options]
    return
  }

  filteredOptions.value = props.options.filter(option => {
    const labelMatch = option[optionLabel].toLowerCase().includes(query)
    const searchableMatch = option.searchableText?.toLowerCase().includes(query)
    return labelMatch || searchableMatch
  })
}
```

## The Dual Search

| Field            | Purpose                                 |
|------------------|-----------------------------------------|
| `optionLabel`    | Display text (product name)             |
| `searchableText` | Additional search content (SKU, barcode) |

## The Workarounds

### 1. Empty Query Spread
PrimeVue watcher doesn't trigger without spread operator:
```typescript
filteredOptions.value = [...props.options]  // Works
filteredOptions.value = props.options       // Doesn't work
```

### 2. Fluid Width Bug (v4.3.4+)
PrimeVue fluid prop doesn't apply width: 100%:
```scss
<style scoped>
:deep(.p-autocomplete-fluid) {
  width: 100%;
}
</style>
```

## The Rules

1. **Dual search fields**: Support optionLabel + searchableText
2. **Client-side filtering**: Filter in ref, not computed (mutable)
3. **Re-filter on options change**: Watch options prop for async data
4. **Document workarounds**: Comment the PrimeVue bugs

## The Anti-Patterns

| Don't                         | Do                               |
|-------------------------------|----------------------------------|
| Single field search           | Search label + searchableText    |
| Computed for filtered options | Use ref (allows mutation)        |
| Skip spread on empty query    | Always spread to trigger watcher |
| Assume fluid works            | Add :deep style workaround       |
