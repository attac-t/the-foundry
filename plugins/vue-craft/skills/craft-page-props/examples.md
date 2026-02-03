# Page Props: Examples

Page props patterns from production code.

---

## The Pattern

### Props Per Page Type
**Why?** Each page has different data needs.

```typescript
// domains/fees/types/pages/FeePagesProps.types.ts

import type { PaginatedResponse } from '@/domains/pagination/types/responses/PaginatedResponse'
import type { FeeModel } from '@/domains/fees/types/models/FeeModel'
import type { VatsModel } from '@/domains/inventory/types/models/VatModel'

/**
 * Props for Fees Index page
 */
interface FeeIndexProps {
  fees: PaginatedResponse<FeeModel>
}

/**
 * Props for Fees New page
 */
interface FeeNewProps {
  vatRates: VatsModel
}

/**
 * Props for Fees Edit page
 */
interface FeeEditProps {
  fee: FeeModel
  vatRates: VatsModel
}

export type { FeeIndexProps, FeeNewProps, FeeEditProps }
```

---

## Common Scenarios

### Usage in Page
**Why?** Type-safe props from controller.

```vue
<script lang="ts" setup>
import type { FeeNewProps } from '@/domains/fees/types/pages/FeePagesProps.types'

defineProps<FeeNewProps>()
</script>
```

### Shared Dependencies
**Why?** Multiple pages need same data.

```typescript
// Both New and Edit need vatRates
interface FeeNewProps {
  vatRates: VatsModel
}

interface FeeEditProps {
  fee: FeeModel
  vatRates: VatsModel  // Same dependency
}
```

### Paginated Index
**Why?** Index pages get paginated responses.

```typescript
interface InvoiceIndexProps {
  invoices: PaginatedResponse<InvoiceModel>
  filters?: InvoiceFilters
}
```

### Show Page
**Why?** Show pages get single entity.

```typescript
interface InvoiceShowProps {
  invoice: Invoice
}
```
