# Namespacing: Examples

Real-world examples of namespace placement decisions.

---

## Laravel Framework

### Illuminate\Support
**Why?** Generic utilities, zero business logic.
```php
// These are Support-level concepts
Illuminate\Support\Str::slug()
Illuminate\Support\Arr::get()
Illuminate\Support\Collection::class
```

### Illuminate\Contracts
**Why?** Interfaces are package-ready.
```php
// Contracts define boundaries
Illuminate\Contracts\Queue\ShouldQueue
Illuminate\Contracts\Mail\Mailable
Illuminate\Contracts\Auth\Authenticatable
```

---

## Vendor Packages (Support Examples)

### Spatie Laravel Data
**Why?** Generic DTO framework, no business knowledge.
```php
use Spatie\LaravelData\Data;

// Package doesn't know your domain
// Your DTOs extend it with business meaning
```

### Brick\Money
**Why?** Generic money handling, works anywhere.
```php
use Brick\Money\Money;

Money::of(100, 'USD');  // Pure value object
```

### League\Fractal
**Why?** Generic transformation, no domain coupling.
```php
use League\Fractal\TransformerAbstract;

// Transformer pattern is domain-agnostic
```

---

## Support (Generic)

### Money Value Object
**Why?** Zero business knowledge. Works anywhere.
```php
namespace Support\Money;

class Money
{
    public function __construct(
        public readonly int $minorAmount,
        public readonly string $currency = 'USD',
    ) {}

    public function add(Money $other): self { /* ... */ }
}
```

### Filter Abstraction
**Why?** Generic query filtering. No business entities.
```php
namespace Support\Filters;

abstract class BaseFilter
{
    abstract public function apply(Builder $query, mixed $value): void;
}
```

---

## Domain (Business)

### Price List Action
**Why?** Knows about `PriceList` model. Business rules.
```php
namespace Domain\Pricing\Actions;

use Domain\Pricing\Models\PriceList;  // Domain import

class ApplyPriceListAdjustmentAction { /* ... */ }
```

### Domain Uses Support
**Why?** Domain imports Support, never reverse.
```php
namespace Domain\Pricing\Models;

use Support\Money\Money;      // Allowed
use Support\Percentage;       // Allowed
```

---

## The Golden Rule

### Support NEVER Imports Domain
```php
// FORBIDDEN in Support
use Domain\Orders\Models\Order;

// If you need Order, move to Domain
namespace Domain\Reports\Actions;
use Domain\Orders\Models\Order;
```

---

## Anti-Patterns

### Support Imports Domain
**Why wrong?** Breaks package boundary.
```php
// Bad: support/Reports/SalesReport.php
use Domain\Orders\Models\Order;

// Good: move to domain/Reports/
namespace Domain\Reports;
```

### Generic Utility in Domain
**Why wrong?** Doesn't need business context.
```php
// Bad: domain/Utils/StringHelper.php
class StringHelper { slugify(), truncate() }

// Good: support/Utils/ or just use Str::
```
