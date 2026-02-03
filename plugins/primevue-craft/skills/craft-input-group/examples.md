# Examples: Input Group

---

## Directory Structure

```
components/
├── atoms/inputs/
│   ├── ifta-or-float-label/IftaOrFloatLabel.vue
│   ├── input-label/InputLabel.vue
│   └── input-error/InputError.vue
└── molecules/prime/form/
    ├── input-label-message-group/
    ├── input-text-group/
    ├── input-number-group/
    ├── input-textarea-group/
    └── [other input groups]
```

---

## Basic InputTextGroup

```vue
<template>
  <InputTextGroup
    v-model="form.name"
    label="Customer Name"
    name="customer-name"
    :state="validation.name.valid"
    :message="validation.name.message"
  />
</template>
```

---

## Label Types

```vue
<!-- Traditional label (default) -->
<InputTextGroup label="Name" name="name" />

<!-- Float label -->
<InputTextGroup label="Name" name="name" label-type="float" />

<!-- IFTA label -->
<InputTextGroup label="Name" name="name" label-type="ifta" />
```

---

## IftaOrFloatLabel Implementation

```vue
<template>
  <Component :is="wrapperComponent" :class="{ 'w-full': fluid }">
    <slot />
  </Component>
</template>

<script setup lang="ts">
import { FloatLabel, IftaLabel } from 'primevue'

const wrapperComponent = computed(() => {
  if (props.labelType === 'float') return FloatLabel
  if (props.labelType === 'ifta') return IftaLabel
  return 'div'
})
</script>
```

---

## InputLabelMessageGroup Implementation

```vue
<template>
  <IftaOrFloatLabel :label-type="labelType" :fluid="fluid">
    <!-- Traditional label (not float/ifta) -->
    <div v-if="!labelType" :class="{ 'flex items-center gap-4': inline }">
      <InputLabel
        v-if="label"
        :for="name"
        :class="inline ? 'w-40' : ''"
      >
        {{ label }}
      </InputLabel>

      <div :class="{ 'flex-1': inline }">
        <slot />
        <InputError v-if="state === false && message">
          {{ message }}
        </InputError>
      </div>
    </div>

    <!-- Float/IFTA labels (no InputLabel component) -->
    <template v-else>
      <slot />
      <label :for="name">{{ label }}</label>
      <InputError v-if="state === false && message">
        {{ message }}
      </InputError>
    </template>
  </IftaOrFloatLabel>
</template>
```

---

## Placeholder Proxy Pattern

```typescript
// Float labels handle placeholder via label itself
// Traditional labels show placeholder in input

const placeholderProxy = computed(() => {
  if (props.labelType === 'float' || props.labelType === 'ifta') {
    return ''  // Empty - label acts as placeholder
  }
  return props.placeholder
})
```

---

## Unique Field Names

```typescript
import { uniqueId } from 'lodash-es'

const fieldName = computed(() => uniqueId(`${props.name}-`))

// Used for:
// - Input id attribute
// - Label htmlFor attribute
// - Accessibility association
```

---

## Validation State Conversion

```typescript
interface Props {
  state?: boolean | null
}

// PrimeVue uses 'invalid' prop
const isInvalid = computed(() => props.state === false)

// Show error message only when invalid
const showError = computed(() =>
  props.state === false && !!props.message
)
```

---

## Trailing Slot

```vue
<InputTextGroup v-model="search" name="search">
  <template #trailing>
    <i class="pi pi-search" />
  </template>
</InputTextGroup>
```

---

## Inline Layout

```vue
<!-- Label and input on same row -->
<InputTextGroup
  v-model="value"
  label="Amount"
  name="amount"
  inline
  label-class="w-32"  <!-- Override default w-40 -->
/>
```
