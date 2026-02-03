# Examples: Panel

---

## Directory Structure

```
components/atoms/prime/panel/
└── twn-panel/
    ├── TwnPanel.vue
    └── TwnPanel.types.ts
```

---

## Basic Usage

```vue
<template>
  <TwnPanel header="Invoice Details">
    <InvoiceForm v-model="form" />
  </TwnPanel>
</template>
```

---

## Controlled Collapse

```vue
<template>
  <TwnPanel
    v-model:collapsed="isDetailsCollapsed"
    header="Additional Details"
  >
    <AdditionalDetailsForm v-model="details" />
  </TwnPanel>
</template>

<script setup lang="ts">
const isDetailsCollapsed = ref(true)  // Start collapsed
</script>
```

---

## With Badge

```vue
<TwnPanel
  header="Validation Errors"
  :badge="{ value: errorCount, severity: 'danger' }"
>
  <ErrorList :errors="errors" />
</TwnPanel>
```

---

## Disabled State

```vue
<TwnPanel
  header="Locked Section"
  :disabled="!canEdit"
>
  <!-- Content -->
</TwnPanel>
```

---

## Implementation

```vue
<template>
  <Panel :collapsed="collapsed" :pt="panelPt">
    <template #header>
      <div
        class="flex items-center justify-between w-full cursor-pointer"
        :class="{ 'opacity-50': disabled }"
        @click="toggle"
      >
        <div class="flex items-center gap-2">
          <i :class="chevronIcon" />
          <span>{{ header }}</span>
        </div>

        <TwnTag
          v-if="badge"
          :value="badge.value"
          :severity="badge.severity"
        />
      </div>
    </template>

    <!-- Lazy content rendering -->
    <template v-if="!collapsed">
      <slot />
    </template>
  </Panel>
</template>

<script setup lang="ts">
const chevronIcon = computed(() =>
  collapsed.value ? 'pi pi-chevron-right' : 'pi pi-chevron-down'
)

const toggle = () => {
  if (props.disabled) return
  collapsed.value = !collapsed.value
  emit('update:collapsed', collapsed.value)
}
</script>
```

---

## PT Configuration

```typescript
const panelPt = {
  root: { class: 'border rounded-lg' },
  header: {
    class: [
      'p-4 border-b cursor-pointer',
      'hover:bg-surface-100 transition-colors'
    ]
  },
  content: { class: 'p-4' },
  toggler: { class: 'hidden' }  // Hide default toggler
}
```

---

## Type Definitions

```typescript
interface TwnPanelProps {
  header: string
  collapsed?: boolean
  disabled?: boolean
  badge?: {
    value: number | string
    severity?: 'success' | 'info' | 'warn' | 'danger'
  }
}

interface TwnPanelEmits {
  'update:collapsed': [value: boolean]
}
```

---

## Multiple Panels (Accordion-like)

```vue
<template>
  <div class="space-y-4">
    <TwnPanel
      v-for="section in sections"
      :key="section.id"
      :header="section.title"
      v-model:collapsed="section.collapsed"
    >
      <component :is="section.component" />
    </TwnPanel>
  </div>
</template>
```
