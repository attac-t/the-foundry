# Examples: Form Agent

---

## Directory Structure

```
composables/
└── use-form/
    ├── useFormAgent.ts
    └── useFormAgent.types.ts
```

---

## Basic Usage

```typescript
import { useFormAgent } from '@/composables/use-form/useFormAgent'

const defaultInvoice: CreateInvoiceRequest = {
  customer_id: null,
  items: [],
  notes: '',
  due_date: null
}

// Props come from Inertia page, may be partial
const { state, form } = useFormAgent(props.invoice, defaultInvoice)

// Reactive access - state is the source of truth
const customerName = computed(() =>
  customers.value.find(c => c.id === state.value.customer_id)?.name
)

// Submit - slug automatically stripped
const save = () => {
  form.post(route('invoices.store'))
}
```

---

## Array Handling

```typescript
const defaultItems: LineItem[] = []

// Arrays are cloned, not merged (prevents object corruption)
const { state, form } = useFormAgent(props.items, defaultItems)

// Add item - watcher syncs to form
state.value.push({ product_id: 1, quantity: 1, price: 100 })
```

---

## Type Definition

```typescript
interface UseFormAgentReturn<T> {
  state: Ref<T>
  form: InertiaForm<T>
}

const useFormAgent = <T extends Record<string, unknown> | unknown[]>(
  initialValue: T extends unknown[] ? T : Partial<T>,
  defaultValue: T
): UseFormAgentReturn<T>
```

---

## Prohibited Keys

```typescript
// These keys are stripped before form submission:
// - slug (prevents accidental route param mutations)

// Before sync:
{ name: 'Invoice', slug: 'inv-123', total: 100 }

// After sync to form:
{ name: 'Invoice', slug: undefined, total: 100 }
```

---

## Merge Behavior

```typescript
// Defaults
{ customer_id: null, notes: '', items: [] }

// Initial (from props, partial)
{ customer_id: 42, items: [{ id: 1 }] }

// Merged result
{ customer_id: 42, notes: '', items: [{ id: 1 }] }

// Order: merge({}, defaults, initial)
// Defaults provide shape, initial overwrites values
```
