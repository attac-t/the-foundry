# Examples: SlideOver

---

## Directory Structure

```
components/molecules/overlays/
└── app-slide-over/
    ├── AppSlideOver.vue
    └── AppSlideOver.types.ts
```

---

## Basic Usage

```vue
<template>
  <Button label="Open" @click="showSlideOver = true" />

  <AppSlideOver
    v-model:visible="showSlideOver"
    title="Invoice Details"
    subtitle="INV-2024-001"
  >
    <InvoiceForm v-model="form" />

    <template #footer>
      <Button label="Cancel" severity="secondary" @click="close" />
      <Button label="Save" @click="save" />
    </template>
  </AppSlideOver>
</template>

<script setup lang="ts">
const showSlideOver = ref(false)
const close = () => { showSlideOver.value = false }
</script>
```

---

## With Header Actions

```vue
<AppSlideOver v-model:visible="visible" title="Edit Product">
  <template #header-actions>
    <Button icon="pi pi-trash" severity="danger" text @click="confirmDelete" />
    <Button icon="pi pi-copy" text @click="duplicate" />
  </template>

  <!-- Content -->
</AppSlideOver>
```

---

## Size Variants

```vue
<!-- Medium (default): w-1/3 on desktop -->
<AppSlideOver size="md" />

<!-- Large: w-1/2 on desktop -->
<AppSlideOver size="lg" />

<!-- Both: 90% height on mobile -->
```

---

## Responsive Implementation

```typescript
import { useTailwindBreakpoints } from '@/composables/use-tailwind-breakpoints'

const { isXlAndUp } = useTailwindBreakpoints()

const position = computed(() => isXlAndUp.value ? 'right' : 'bottom')

const sizeStyle = computed(() => {
  if (!isXlAndUp.value) return { height: '90%' }

  return props.size === 'lg'
    ? { width: '50%' }
    : { width: '33.333%' }
})
```

---

## Lifecycle Events

```vue
<AppSlideOver
  @show="handleShow"
  @before-hide="handleBeforeHide"
  @hide="handleHide"
  @after-hide="handleAfterHide"
  @after-show="handleAfterShow"
/>
```

---

## Slot Structure

```vue
<template>
  <Drawer :position="position" :blockScroll="true">
    <!-- Header -->
    <template #header>
      <div class="flex items-center justify-between w-full">
        <div>
          <h2>{{ title }}</h2>
          <p v-if="subtitle">{{ subtitle }}</p>
        </div>
        <div class="flex gap-2">
          <slot name="header-actions" />
        </div>
      </div>
    </template>

    <!-- Scrollable content -->
    <div class="flex-1 overflow-y-auto">
      <slot />
    </div>

    <!-- Sticky footer -->
    <template v-if="$slots.footer" #footer>
      <div class="border-t pt-4">
        <slot name="footer" />
      </div>
    </template>
  </Drawer>
</template>
```

---

## Mobile vs Desktop

```
Desktop (xl and up):
┌──────────────────────────────────┐
│                          │ w-1/3 │
│         Page             │       │
│                          │SlideO │
│                          │       │
└──────────────────────────────────┘

Mobile (below xl):
┌──────────────────────────────────┐
│                                  │
│           Page                   │
├──────────────────────────────────┤
│         SlideOver (90% h)        │
└──────────────────────────────────┘
```
