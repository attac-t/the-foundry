# Domain Evolution: Examples

Patterns for evolving domain structure.

---

## Splitting Domains

### Before: Monolith Domain
```
src/Domain/Sales/
├── Actions/
│   ├── CreateOrderAction.php
│   ├── CreateInvoiceAction.php
│   ├── ProcessPaymentAction.php
│   ├── GenerateReportAction.php
│   └── SendReminderAction.php
├── Models/
│   ├── Order.php
│   ├── Invoice.php
│   ├── Payment.php
│   └── Report.php
```

### After: Split by Subdomain
```
src/Domain/Orders/
├── Actions/CreateOrderAction.php
└── Models/Order.php

src/Domain/Invoicing/
├── Actions/
│   ├── CreateInvoiceAction.php
│   └── SendReminderAction.php
└── Models/Invoice.php

src/Domain/Payments/
├── Actions/ProcessPaymentAction.php
└── Models/Payment.php

src/Domain/Reporting/
├── Actions/GenerateReportAction.php
└── Models/Report.php
```

---

## Signs to Split

### ⚠️ Too Many Files
```
# If you see 20+ actions in one domain
ls Domain/Sales/Actions/ | wc -l
# 47

# Time to split
```

### ⚠️ Unrelated Concepts
```php
// In same namespace but different concerns
Domain\Sales\Actions\CreateOrderAction      // Order lifecycle
Domain\Sales\Actions\SendMarketingEmail     // Marketing?!
Domain\Sales\Actions\CalculateCommission    // Finance?!
```

### ⚠️ Different Change Frequencies
```
# Orders change weekly (new features)
# Reporting changes monthly (new reports)
# Payments change rarely (stable)

# Different change rates = different domains
```

---

## Merging Domains

### Before: Over-Granular
```
src/Domain/CustomerName/
src/Domain/CustomerEmail/
src/Domain/CustomerAddress/
src/Domain/CustomerPhone/
```

### After: Consolidated
```
src/Domain/Customers/
├── Models/Customer.php
└── ValueObjects/
    ├── Email.php
    └── Address.php
```

---

## The ADR

```markdown
# ADR-007: Split Sales into Orders, Invoicing, Payments

## Status
Accepted

## Context
Sales domain has grown to 47 actions and 12 models.
Different team members work on orders vs payments.
Change frequency varies significantly.

## Decision
Split into three domains with clear boundaries.

## Consequences
- Clearer ownership
- Smaller, focused tests
- Initial migration effort (~2 days)
```
