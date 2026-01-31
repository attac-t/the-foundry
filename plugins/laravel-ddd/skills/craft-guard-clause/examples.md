# Guard Clause: Examples

Patterns for early returns.

---

## The Pattern

### ❌ Without Guards (Nested)
**Why?** Hard to follow. Happy path buried in nesting.
```php
public function processOrder(Order $order): void
{
    if ($order->isPaid()) {
        if ($order->hasStock()) {
            if ($order->isShippable()) {
                $this->ship($order);
            } else {
                throw new NotShippableException();
            }
        } else {
            throw new OutOfStockException();
        }
    } else {
        throw new UnpaidOrderException();
    }
}
```

### ✅ With Guards (Flat)
**Why?** Each guard handles one case. Happy path is clear.
```php
public function processOrder(Order $order): void
{
    if (! $order->isPaid()) {
        throw new UnpaidOrderException();
    }

    if (! $order->hasStock()) {
        throw new OutOfStockException();
    }

    if (! $order->isShippable()) {
        throw new NotShippableException();
    }

    // Happy path
    $this->ship($order);
}
```

---

## Guard Variants

### Throw Exception
**When**: Caller must handle the failure.
```php
if (! $user->canEdit($post)) {
    throw new UnauthorizedException();
}
```

### Return Early (Void)
**When**: Nothing to do is acceptable.
```php
if ($order->isAlreadyProcessed()) {
    return;
}
```

### Return Default
**When**: Empty result is meaningful.
```php
if ($items->isEmpty()) {
    return collect();
}
```

### Return Result Object
**When**: Caller needs context about why.
```php
if (! $context->isValid()) {
    return SyncResult::skipped('Invalid context');
}
```

---

## Production Pattern

### ✅ Guards with Result Objects
**Why?** Combines guard clause benefits with rich feedback.
```php
public function execute(SyncContext $context): SyncResult
{
    if (! $context->provider) {
        return SyncResult::failed('Provider required');
    }

    if ($context->startDate->isAfter($context->endDate)) {
        return SyncResult::failed('Invalid date range');
    }

    if ($this->isRateLimited($context->provider)) {
        return SyncResult::skipped('Rate limited');
    }

    // Happy path
    $records = $this->sync($context);

    return SyncResult::success($records);
}
```

---

## Anti-Pattern: Too Many Guards

### ❌ Guard Explosion
**Why?** Method does too much. Split it.
```php
public function execute(Order $order): void
{
    if (! $order->customer) { throw new Exception(); }
    if (! $order->items) { throw new Exception(); }
    if (! $order->isPaid()) { throw new Exception(); }
    if (! $order->isApproved()) { throw new Exception(); }
    if ($order->isShipped()) { throw new Exception(); }
    if ($order->isCancelled()) { throw new Exception(); }
    if (! $this->hasStock($order)) { throw new Exception(); }
    if (! $this->canShip($order)) { throw new Exception(); }
    // ...
}
```

### ✅ Split Responsibilities
```php
public function execute(Order $order): void
{
    $this->validateOrder($order);
    $this->validateFulfillment($order);

    $this->ship($order);
}
```
