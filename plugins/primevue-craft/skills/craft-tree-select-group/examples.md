# Examples: TreeSelect Group

---

## Directory Structure

```
components/molecules/prime/form/
└── input-tree-select-group/
    ├── InputTreeSelectGroup.vue
    └── InputTreeSelectGroup.types.ts
```

---

## Basic Usage

```vue
<template>
  <InputTreeSelectGroup
    v-model="form.categories"
    :options="categoryTree"
    selection-mode="checkbox"
    label="Categories"
    name="categories"
  />
</template>
```

---

## Memoization Caches

```typescript
// Build caches on mount for O(1) lookups
const buildCaches = (nodes: TreeNode[]) => {
  const nodeMap = new Map<string, TreeNode>()
  const descendantKeysCache = new Map<string, string[]>()
  const treeMap = new Map<string, string>()

  const traverse = (node: TreeNode, parentKey?: string) => {
    nodeMap.set(node.key, node)

    if (parentKey) {
      treeMap.set(node.key, parentKey)
    }

    if (node.children) {
      const descendants: string[] = []

      node.children.forEach(child => {
        descendants.push(child.key)
        traverse(child, node.key)

        // Include grandchildren
        const childDescendants = descendantKeysCache.get(child.key)
        if (childDescendants) {
          descendants.push(...childDescendants)
        }
      })

      descendantKeysCache.set(node.key, descendants)
    }
  }

  nodes.forEach(node => traverse(node))

  return { nodeMap, descendantKeysCache, treeMap }
}
```

---

## Consolidation Logic

```typescript
// When all children selected, consolidate to parent
const consolidateSelection = (selection: Record<string, boolean>) => {
  const consolidated = { ...selection }

  // Check each node with children
  nodeMap.forEach((node, key) => {
    if (!node.children) return

    const descendants = descendantKeysCache.get(key) || []
    const allDescendantsSelected = descendants.every(d => consolidated[d])

    if (allDescendantsSelected && descendants.length > 0) {
      // Remove children, add parent
      descendants.forEach(d => delete consolidated[d])
      consolidated[key] = true
    }
  })

  return consolidated
}
```

---

## Expansion Logic

```typescript
// When child unselected from consolidated parent, expand to siblings
const expandSelection = (
  selection: Record<string, boolean>,
  unselectedKey: string
) => {
  const expanded = { ...selection }
  const parentKey = treeMap.get(unselectedKey)

  if (!parentKey) return expanded

  // If parent was selected (consolidated)
  if (expanded[parentKey]) {
    delete expanded[parentKey]

    // Add all siblings except the unselected one
    const siblings = descendantKeysCache.get(parentKey) || []
    siblings.forEach(sibling => {
      if (sibling !== unselectedKey) {
        expanded[sibling] = true
      }
    })
  }

  return expanded
}
```

---

## v-model Conversion

```typescript
// Convert internal selection to v-model format based on mode
const convertToModel = (selection: InternalSelection) => {
  if (props.selectionMode === 'single') {
    return Object.keys(selection)[0] || null
  }

  if (props.selectionMode === 'checkbox') {
    return {
      checked: selection,
      partialChecked: computePartialChecked(selection)
    }
  }

  return selection
}
```

---

## Fluid Width Workaround

```vue
<style scoped>
/* PrimeVue v4.3.4+ bug: fluid doesn't apply width: 100% */
:deep(.p-treeselect-fluid) {
  width: 100%;
}
</style>
```

---

## Selection Mode Examples

```vue
<!-- Single selection -->
<InputTreeSelectGroup
  v-model="selectedCategory"
  :options="categories"
  selection-mode="single"
/>
<!-- v-model: "category-1" -->

<!-- Multiple selection -->
<InputTreeSelectGroup
  v-model="selectedCategories"
  :options="categories"
  selection-mode="multiple"
/>
<!-- v-model: { "category-1": true, "category-2": true } -->

<!-- Checkbox with partial -->
<InputTreeSelectGroup
  v-model="selectedCategories"
  :options="categories"
  selection-mode="checkbox"
/>
<!-- v-model: { checked: {...}, partialChecked: {...} } -->
```

---

## Events

```vue
<InputTreeSelectGroup
  v-model="selected"
  :options="categories"
  @change="handleChange"
  @node-select="handleNodeSelect"
  @node-unselect="handleNodeUnselect"
  @node-expand="handleExpand"
  @node-collapse="handleCollapse"
/>
```
