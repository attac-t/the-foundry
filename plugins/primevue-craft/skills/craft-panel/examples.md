# Examples: Panel

---

## Directory Structure

```
components/atoms/prime/panel/
└── app-panel/
    ├── AppPanel.vue
    └── AppPanel.types.ts
```

---

## Basic Usage

```vue
<template>
  <AppPanel header="Invoice Details">
    <InvoiceForm v-model="form" />
  </AppPanel>
</template>
```

---

## Controlled Collapse

```vue
<template>
  <AppPanel
    v-model:collapsed="isDetailsCollapsed"
    header="Additional Details"
  >
    <AdditionalDetailsForm v-model="details" />
  </AppPanel>
</template>

<script setup lang="ts">
const isDetailsCollapsed = ref(true)  // Start collapsed
</script>
```

---

## With Badge

```vue
<AppPanel
  header="Validation Errors"
  :badge="{ value: errorCount, severity: 'danger' }"
>
  <ErrorList :errors="errors" />
</AppPanel>
```

---

## Disabled State

```vue
<AppPanel
  header="Locked Section"
  :disabled="!canEdit"
>
  <!-- Content -->
</AppPanel>
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

        <AppTag
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
interface AppPanelProps {
  header: string
  collapsed?: boolean
  disabled?: boolean
  badge?: {
    value: number | string
    severity?: 'success' | 'info' | 'warn' | 'danger'
  }
}

interface AppPanelEmits {
  'update:collapsed': [value: boolean]
}
```

---

## Multiple Panels (Accordion-like)

```vue
<template>
  <div class="space-y-4">
    <AppPanel
      v-for="section in sections"
      :key="section.id"
      :header="section.title"
      v-model:collapsed="section.collapsed"
    >
      <component :is="section.component" />
    </AppPanel>
  </div>
</template>
```
