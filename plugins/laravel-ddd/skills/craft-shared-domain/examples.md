# Shared Domain: Examples

Patterns for cross-cutting concerns.

---

## Good Shared Content

### ✅ Audit Logging
```
src/Domain/Shared/
├── Traits/
│   └── Auditable.php
├── Models/
│   └── AuditLog.php
└── Events/
    └── ModelAuditedEvent.php
```

### ✅ Base Classes
```
src/Domain/Shared/
├── Models/
│   └── BaseModel.php      # Common model configuration
└── Actions/
    └── BaseAction.php     # Shared action behavior
```

### ✅ Value Objects Used Everywhere
```
src/Domain/Shared/
└── ValueObjects/
    ├── Money.php          # Used by Orders, Invoices, Payments
    └── DateRange.php      # Used by Reports, Scheduling
```

---

## Bad Shared Content

### ❌ Business Logic
```
// This is NOT shared—it belongs to Invoicing
src/Domain/Shared/Actions/CalculateInvoiceTotalAction.php

// Move to:
src/Domain/Invoicing/Actions/CalculateTotalAction.php
```

### ❌ "Common" Dumping Ground
```
src/Domain/Shared/
├── Actions/
│   ├── SendEmailAction.php      # → Support/Mail
│   ├── GeneratePdfAction.php    # → Support/Pdf
│   ├── UploadFileAction.php     # → Support/Storage
│   └── ValidateDataAction.php   # → Domain that uses it
```

---

## Shared vs Support

### Shared (Domain Layer)
```
src/Domain/Shared/
└── ValueObjects/Money.php    # Domain concept, used by multiple domains
```

### Support (Infrastructure Layer)
```
src/Support/
├── Ledger/LedgerClient.php       # Integration
├── Pdf/PdfGenerator.php      # Utility
└── Mail/MailBuilder.php      # Infrastructure
```

---

## Signs Shared Is Too Large

### ⚠️ Red Flags
```bash
# If you see this:
ls src/Domain/Shared/Actions/ | wc -l
# 15+

# You have a domain discovery problem
# These "shared" actions belong somewhere
```

### ✅ Resolution
```
# Analyze usage
grep -r "CalculateTaxAction" src/Domain/

# If only used by Invoicing → move to Invoicing
# If used by 3+ domains → might be truly Shared
# If used by 2 related domains → create parent domain
```
