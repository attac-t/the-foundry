# Domain Structure: Examples

Patterns for consistent domain layout.

---

## The Standard Structure

### ✅ Complete Domain
```
src/Domain/Invoicing/
├── Actions/
│   ├── CreateInvoiceAction.php
│   ├── SendInvoiceAction.php
│   └── VoidInvoiceAction.php
├── DTOs/
│   ├── CreateInvoiceData.php
│   └── InvoiceData.php
├── Events/
│   ├── InvoiceCreatedEvent.php
│   └── InvoicePaidEvent.php
├── Models/
│   ├── Invoice.php
│   └── InvoiceLine.php
├── QueryBuilders/
│   └── InvoiceQueryBuilder.php
├── Collections/
│   └── InvoiceLineCollection.php
├── States/
│   ├── InvoiceState.php
│   ├── DraftInvoiceState.php
│   ├── SentInvoiceState.php
│   └── PaidInvoiceState.php
└── Subscribers/
    └── InvoiceSubscriber.php
```

---

## Minimal Domain

### ✅ Small Domain (Start Here)
```
src/Domain/Tags/
├── Actions/
│   └── SyncTagsAction.php
└── Models/
    └── Tag.php
```

---

## Layer Boundary

### ✅ App Layer (Orchestration)
```
app/
├── Http/
│   └── Controllers/
│       └── InvoiceController.php    # Uses Domain Actions
├── Jobs/
│   └── SendInvoiceReminderJob.php   # Dispatches to Domain
└── Console/
    └── Commands/
        └── SendOverdueReminders.php # Orchestrates Domain
```

### ✅ Domain Layer (Business Logic)
```
src/Domain/Invoicing/
└── Actions/
    └── SendReminderAction.php       # Pure business logic
```

### ✅ Support Layer (Infrastructure)
```
src/Support/
├── Mail/
│   └── MailBuilder.php
└── Pdf/
    └── PdfGenerator.php
```

---

## Folder Conventions

| Folder           | Contains                    | Example                 |
| ---------------- | --------------------------- | ----------------------- |
| `Actions/`       | Business logic entry points | `CreateInvoiceAction`   |
| `DTOs/`          | Data transfer objects       | `CreateInvoiceData`     |
| `Models/`        | Eloquent models             | `Invoice`               |
| `Events/`        | Domain events               | `InvoicePaidEvent`      |
| `States/`        | State pattern classes       | `PaidInvoiceState`      |
| `QueryBuilders/` | Custom query builders       | `InvoiceQueryBuilder`   |
| `Collections/`   | Custom collections          | `InvoiceLineCollection` |
| `Subscribers/`   | Event subscribers           | `InvoiceSubscriber`     |
| `ValueObjects/`  | Immutable value objects     | `InvoiceNumber`         |

---

## composer.json Autoload

```json
{
    "autoload": {
        "psr-4": {
            "App\\": "app/",
            "Domain\\": "src/Domain/",
            "Support\\": "src/Support/"
        }
    }
}
```
