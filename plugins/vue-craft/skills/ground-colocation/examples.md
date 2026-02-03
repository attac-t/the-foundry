# Colocation: Examples

Domain boundaries and anti-patterns.

---

## Structure Anti-Patterns

### Layer-Based Organization
**Why?** Changes scatter across the codebase.

```
// Bad: technical layers
src/
├── components/
│   ├── InvoiceForm.vue
│   └── InvoiceTable.vue
├── stores/
│   └── invoiceStore.ts
├── types/
│   └── Invoice.ts
└── composables/
    └── useInvoice.ts

// Good: domain colocation
src/domains/invoices/
├── components/
│   └── organisms/
│       ├── invoice-form/
│       └── invoice-table/
├── store/
│   └── useInvoiceStore.ts
├── types/
│   └── models/
│       └── Invoice.types.ts
└── composables/
    └── use-invoice/
```

---

## Boundary Signals

### Self-Contained Domain
**Why?** Delete the folder, delete the feature.

```
domains/invoices/
├── components/          # UI for this domain
├── composables/         # Logic for this domain
├── store/               # State for this domain
├── types/               # Types for this domain
├── utils/               # Utilities for this domain
└── validations/         # Validation for this domain
```

### Shared Code Stays Shared
**Why?** Cross-domain code has a home.

```
// Shared composables (used by multiple domains)
src/composables/use-entity-notification/

// Domain-specific composables (one domain only)
src/domains/invoices/composables/use-invoice-calculation/
```
