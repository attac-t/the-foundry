# Provider Component: Examples

Renderless context providers from production code.

---

## The Pattern

### Provider Component
**Why?** Sets up shared context. No DOM output.

```vue
<!-- TwnWorkSessionSelectOptionsProvider.vue -->
<template>
  <slot />
</template>

<script lang="ts" setup>
/**
 * TwnWorkSessionSelectOptionsProvider
 *
 * A provider component that sets up shared select options context.
 * Uses domain-specific injection keys from the types file.
 */
import { useFindSelectOptionsCtxProvider } from '@/composables/use-find-select-options-ctx/useFindSelectOptionsCtx'
import {
  WorkSessionLocationsSelectCtx,
  WorkSessionUsersSelectCtx
} from './TwkWorkSessionSelectOptionsProvider.types'

// Set up providers for shared context
useFindSelectOptionsCtxProvider({ provideCtx: WorkSessionLocationsSelectCtx })
useFindSelectOptionsCtxProvider({ provideCtx: WorkSessionUsersSelectCtx })
</script>
```

### Injection Keys
**Why?** Type-safe provide/inject. Colocated with provider.

```typescript
// TwkWorkSessionSelectOptionsProvider.types.ts
import type { InjectionKey, Ref } from 'vue'

/**
 * Injection keys for work session select options context
 * Co-located with the TwnWorkSessionSelectOptionsProvider component
 */

interface SelectOptionsContext<T = any> {
  options: Ref<T[]>
  initiated: Ref<boolean>
  globalBusy: Ref<boolean>
}

// Symbol pattern for unique keys
export const WorkSessionLocationsSelectCtx: InjectionKey<SelectOptionsContext> =
  Symbol('WorkSessionLocationsSelectCtx')

export const WorkSessionUsersSelectCtx: InjectionKey<SelectOptionsContext> =
  Symbol('WorkSessionUsersSelectCtx')
```

---

## Usage

### Wrap Children
**Why?** Children get access to provided context.

```vue
<template>
  <TwnWorkSessionSelectOptionsProvider>
    <!-- All children can inject WorkSessionLocationsSelectCtx -->
    <TwnWorkSessionForm />
    <TwnWorkSessionList />
  </TwnWorkSessionSelectOptionsProvider>
</template>
```

### Child Injection
**Why?** Access shared state without prop drilling.

```typescript
// In a child component
import { inject } from 'vue'
import { WorkSessionLocationsSelectCtx } from '../twn-work-session-select-options-provider/TwkWorkSessionSelectOptionsProvider.types'

const locationsCtx = inject(WorkSessionLocationsSelectCtx)

// Use provided options
const locationOptions = computed(() => locationsCtx?.options.value ?? [])
```
