# Skill: Craft TreeSelect Group

> "Large hierarchies need memoization."

## The Pattern

`InputTreeSelectGroup` wraps PrimeVue TreeSelect with memoized selection handling.

```typescript
// Memoization caches for O(1) lookups
const nodeMap = new Map<string, TreeNode>()           // key → node
const descendantKeysCache = new Map<string, string[]>() // key → all descendants
const treeMap = new Map<string, string>()             // child → parent
```

## The Selection Modes

| Mode     | v-model Type                                | Description         |
|----------|---------------------------------------------|---------------------|
| Single   | `string`                                    | One selection       |
| Multiple | `{ [key]: true }`                           | Multiple selections |
| Checkbox | `{ checked: {...}, partialChecked: {...} }` | With partial states |

## The Consolidation Logic

When all children are selected, collapse to parent:
```typescript
// Selected: A.1, A.2, A.3 (all children of A)
// Becomes: A (parent)
```

When child unselected, expand parent to siblings:
```typescript
// Deselect A.2 from consolidated A
// Becomes: A.1, A.3 (siblings)
```

## The Rules

1. **Memoization**: Build nodeMap, descendantKeysCache, treeMap on mount
2. **Consolidation**: Collapse child selections to parent when complete
3. **Expansion**: Unselecting child expands to individual siblings
4. **Filter mode**: Use 'lenient' for partial matches
5. **Fluid workaround**: Same :deep style as AutoComplete

## The Anti-Patterns

| Don't                         | Do                             |
|-------------------------------|--------------------------------|
| Traverse tree on every render | Build memoization caches       |
| Keep all children in selection | Consolidate to parent          |
| Re-compute descendants        | Cache in descendantKeysCache   |
| Manual parent tracking        | Use treeMap for child→parent   |
