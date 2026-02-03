# Component: Examples

Vue SFC patterns from production code.

---

## defineModel

### Two-Way Binding
**Why?** Replaces verbose computed getter/setter.

```typescript
// Before (Vue 3.3 and earlier)
const props = defineProps<{ modelValue: CreateInvoiceRequest }>()
const emit = defineEmits<{ 'update:modelValue': [value: CreateInvoiceRequest] }>()
const formData = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
})

// After (Vue 3.4+)
const formData = defineModel<CreateInvoiceRequest>({ required: true })

// Usage in parent
<TwnInvoiceForm v-model="formAgent.state.value" />
```

### Named Models
**Why?** Multiple v-model bindings.

```typescript
const visible = defineModel<boolean>('visible', { default: false })

// Usage
<TwnSlideOver v-model:visible="isSlideOverOpen" />
```

---

## Lazy Loading

### Conditional Components
**Why?** Don't load what won't render.

```typescript
// Lazy load components that render conditionally
const LazyTwnInfoState = defineAsyncComponent(
  () => import('@/components/atoms/info/twn-info-state/TwnInfoState.vue')
)

const LazyTwnInvoiceLineItemsSection = defineAsyncComponent(
  () => import('@/domains/invoices/components/organisms/twn-invoice-line-items-section/TwnInvoiceLineItemsSection.vue')
)
```

```html
<!-- Only loads when condition is met -->
<LazyTwnInfoState
  v-if="!isCustomerSelected"
  msg="No customer selected"
/>

<LazyTwnInvoiceLineItemsSection
  v-else
  v-model="formData.line_items"
/>
```

---

## Directory Structure

### Naming Convention
**Why?** Consistent, searchable, domain-scoped.

```
domains/invoices/components/
├── atoms/
│   └── twn-invoice-status-indicator/
│       ├── TwnInvoiceStatusIndicator.vue
│       └── TwnInvoiceStatusIndicator.types.ts
├── molecules/
│   └── twn-invoice-item-content/
│       ├── TwnInvoiceItemContent.vue
│       └── TwnInvoiceItemContent.types.ts
└── organisms/
    └── twn-invoice-form/
        ├── TwnInvoiceForm.vue
        └── TwnInvoiceForm.types.ts
```

---

## Types Colocation

### Separate Types File
**Why?** Reusable. Clean component file.

```typescript
// TwnInvoiceForm.types.ts
export interface TwnInvoiceFormProps {
  createdBy?: string
  displayNumber?: string
  invoiceTotal?: MoneyModel | null
}

// TwnInvoiceForm.vue
import type { TwnInvoiceFormProps } from './TwnInvoiceForm.types'

defineProps<TwnInvoiceFormProps>()
```
