# Laravel Polish: Examples

Concrete before/after patterns for each pass.

---

## Pass 1: Docblocks

### Craftsman Voice
**Why?** One sentence. Verb-first. Present tense.

```php
// Craftsman
/** Determine if the order has been fully paid. */

// Craftsman — type refinement earns its place
/** @param Collection<int, LineItem> $items */

// Craftsman — non-obvious constraint
/** @throws InsufficientBalanceException When the wallet balance cannot cover the remaining amount. */

// Craftsman — external reference
/** @see https://stripe.com/docs/api/payment_intents/create#idempotency */
```

### Bureaucrat — Delete
**Why?** Restates what the signature already declares.

```php
// Before — bureaucrat
/**
 * @param Order $order The order to process
 * @return Invoice The resulting invoice
 */
public static function forOrder(Order $order): self

// After — signature says it all
public static function forOrder(Order $order): self
```

### Ghost — Delete
**Why?** Every constructor creates a new instance. We know.

```php
// Before
/** Create a new instance. */
public function __construct() {}

// After
public function __construct() {}
```

### Narrator — Delete
**Why?** The method is called `isPaid()`. It returns `bool`. One-line body. The code IS the documentation.

```php
// Before — 5-line novel about a 1-line method
/**
 * This method checks whether the order has been fully paid
 * by verifying that there is at least one completed payment
 * associated with this order through the payments relationship.
 */
public function isPaid(): bool
{
    return $this->payments()->where('status', 'completed')->exists();
}

// After — the code speaks
public function isPaid(): bool
{
    return $this->payments()->where('status', 'completed')->exists();
}
```

---

## Pass 3: Methods

### Return Stands Alone
**Why?** The eye gets a clear anchor before the chain unfolds.

```php
public function hasPendingRefund(): bool
{
    return
        $this
            ->refunds()
            ->whereState('status', Pending::class)
            ->exists();
}
```

---

## Pass 4: Framework Internals

### The Substitution Table

| Instead Of                   | Use                                               |
| ---------------------------- | ------------------------------------------------- |
| `foreach` + accumulator      | `Collection::sum()`, `reduce()`, `mapWithKeys()`  |
| `foreach` + filter           | `Collection::filter()`, `reject()`, `where()`     |
| `foreach` + first match      | `Collection::first()`, `sole()`, `firstWhere()`   |
| `foreach` + group            | `Collection::groupBy()`, `mapToGroups()`          |
| `foreach` + transform        | `Collection::map()`, `flatMap()`, `pluck()`       |
| Assign-then-return           | `tap($thing, fn ($t) => $t->save())`              |
| Create-modify-return         | `tap(new Thing, fn ($t) => ...)`                  |
| `array_map(fn..., $arr)`     | `collect($arr)->map(fn...)`                       |
| `!empty($x) && $x->method()` | `$x?->method()` (nullsafe)                        |
| `$val = $val ?? $default`    | `$val ??= $default`                               |
| `config('key') ?? default`   | `config('key', $default)`                         |
| `in_array($val, [...])`      | `collect([...])->contains($val)` or enum `->in()` |
| `if ($cond) { $cb(); }`      | `when($cond, $cb)` if available                   |
| `function ($x) use ($y) {…}` | `fn ($x) => …` when single-expression             |

### Collection Pipeline Over Foreach
**Why?** Same result. Half the lines. Declarative.

```php
// Before — foreach + accumulator
$totals = [];
foreach ($payments as $payment) {
    $method = $payment->method_type;
    $totals[$method] = ($totals[$method] ?? 0) + $payment->amount;
}

// After — Collection pipeline
$totals = $payments
    ->groupBy('method_type')
    ->map(fn (Collection $group) => $group->sum('amount'));
```

### tap() Over Create-Modify-Return
**Why?** One expression. One return. No temporary variable.

```php
// Before
$invoice = new Invoice;
$invoice->order_id = $order->id;
$invoice->issued_at = now();
$invoice->save();
return $invoice;

// After
return tap(new Invoice, function (Invoice $invoice) use ($order) {
    $invoice->order_id = $order->id;
    $invoice->issued_at = now();
    $invoice->save();
});
```

### QueryBuilder Over Scopes
**Why?** Scopes scatter query logic across the model. A builder gives queries a home.

```php
// Before — scopes on the model
public function scopePaid(Builder $query): void { ... }
public function scopeRecent(Builder $query): void { ... }

// After — builder methods, atomic and composable
class OrderQueryBuilder extends Builder
{
    public function paid(): static
    {
        return $this->whereHas('payments', fn ($q) => $q->where('status', 'completed'));
    }

    public function recent(): static
    {
        return $this->where('created_at', '>=', now()->subDays(30));
    }

    public function withItems(): static
    {
        return $this->whereHas('lineItems');
    }
}

// Caller composes:
Order::query()->paid()->recent()->withItems()
```
