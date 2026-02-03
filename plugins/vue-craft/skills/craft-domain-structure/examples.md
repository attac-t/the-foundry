# Domain Structure: Examples

Directory layouts from production code.

---

## The Pattern

### Complete Domain
**Why?** Self-contained. Delete folder, delete feature.

```
domains/invoices/
├── components/
│   ├── atoms/
│   │   └── twn-invoice-status-indicator/
│   │       ├── TwnInvoiceStatusIndicator.vue
│   │       └── TwnInvoiceStatusIndicator.types.ts
│   ├── molecules/
│   │   └── twn-invoice-item-content/
│   └── organisms/
│       ├── twn-invoice-form/
│       └── twn-invoice-table/
├── composables/
│   ├── use-invoice-calculation/
│   │   ├── useInvoiceCalculation.ts
│   │   └── useInvoiceCalculation.types.ts
│   └── use-invoice-helper/
├── store/
│   └── useInvoiceStore.ts
├── types/
│   ├── consts/
│   │   └── InvoiceStatus.types.ts
│   ├── models/
│   │   └── Invoice.types.ts
│   ├── requests/
│   │   └── CreateInvoiceRequest.types.ts
│   └── responses/
├── utils/
│   └── line-item-merger/
└── validations/
    └── ui/
        └── invoiceValidation.schema.ts
```

---

## Component Naming

### Atomic Hierarchy
**Why?** Complexity increases down the tree.

```
atoms/      → Single responsibility, no domain logic
molecules/  → Combines atoms, minimal logic
organisms/  → Full features, domain logic, composables
```

### Naming Convention
**Why?** Find files by name alone.

```
twn-{domain}-{component}/
├── Twn{Domain}{Component}.vue
└── Twn{Domain}{Component}.types.ts

Example:
twn-invoice-form/
├── TwnInvoiceForm.vue
└── TwnInvoiceForm.types.ts
```

---

## Type Subdirectories

### Purpose-Based Organization
**Why?** Different concerns, different directories.

```
types/
├── consts/          # as const + derived types
│   └── InvoiceStatus.types.ts
├── models/          # Domain model interfaces
│   └── Invoice.types.ts
├── requests/        # DTOs sent to API
│   └── CreateInvoiceRequest.types.ts
└── responses/       # DTOs received from API
    └── InvoiceResponse.types.ts
```

---

## Composable Directory

### Types Colocation
**Why?** Change together, live together.

```
use-invoice-calculation/
├── __tests__/
│   └── useInvoiceCalculation.test.ts
├── useInvoiceCalculation.ts
└── useInvoiceCalculation.types.ts
```
