# Guard vs Exception: Examples

When to return early vs when to throw.

---

## Return Early

### ✅ Empty Input
**Why?** Empty in, empty out. Not an error.
```php
public function processItems(Collection $items): Collection
{
    if ($items->isEmpty()) {
        return collect();
    }

    return $items->map(fn ($item) => $this->process($item));
}
```

### ✅ Already Processed (Idempotency)
**Why?** Second call should be safe.
```php
public function markAsShipped(Order $order): void
{
    if ($order->isShipped()) {
        return;  // Already done
    }

    $order->ship();
}
```

### ✅ Skip with Reason (Result Object)
**Why?** Caller needs context about why operation didn't happen.
```php
public function sync(SyncContext $context): SyncResult
{
    if ($this->isRateLimited($context->provider)) {
        return SyncResult::skipped('Rate limited, retry in 60s');
    }

    if ($context->dateRange->isEmpty()) {
        return SyncResult::skipped('No date range specified');
    }

    return SyncResult::success($records);
}
```

---

## Throw Exception

### ✅ Missing Required Data
**Why?** Caller must handle. Can't proceed.
```php
public function createInvoice(Order $order): Invoice
{
    if (! $order->customer) {
        throw new MissingCustomerException($order);
    }

    return Invoice::create([...]);
}
```

### ✅ Unauthorized Access
**Why?** Security violation. Must not proceed silently.
```php
public function deletePost(Post $post, User $user): void
{
    if (! $user->can('delete', $post)) {
        throw new UnauthorizedException();
    }

    $post->delete();
}
```

### ✅ Invalid State (Bug)
**Why?** Should never happen. Developer needs to know.
```php
public function transition(Order $order, string $newState): void
{
    $allowed = $this->allowedTransitions[$order->state] ?? [];

    if (! in_array($newState, $allowed)) {
        throw new InvalidStateTransitionException(
            "Cannot transition from {$order->state} to {$newState}"
        );
    }

    $order->update(['state' => $newState]);
}
```

---

## Hybrid Pattern

### ✅ Safe Exit First, Then Strict
**Why?** Handle benign cases, then be strict about real errors.
```php
public function processPayment(Order $order): PaymentResult
{
    // Benign: already paid
    if ($order->isPaid()) {
        return PaymentResult::alreadyPaid();
    }

    // Benign: zero amount
    if ($order->total->isZero()) {
        return PaymentResult::noPaymentRequired();
    }

    // Error: can't proceed
    if (! $order->paymentMethod) {
        throw new MissingPaymentMethodException($order);
    }

    // Error: invalid state
    if ($order->isCancelled()) {
        throw new InvalidOrderStateException('Cannot pay cancelled order');
    }

    return $this->chargePayment($order);
}
```

---

## Anti-Pattern: Boolean Returns

### ❌ Silent Failure
**Why?** Caller doesn't know which check failed.
```php
public function canProcess(Order $order): bool
{
    if (! $order->isPaid()) return false;
    if (! $order->hasStock()) return false;
    if (! $order->isApproved()) return false;
    return true;
}

// Caller has no idea what went wrong
if (! $this->canProcess($order)) {
    // ???
}
```

### ✅ Rich Feedback
**Why?** Each failure carries context.
```php
public function validateForProcessing(Order $order): ValidationResult
{
    if (! $order->isPaid()) {
        return ValidationResult::failed('Order not paid');
    }

    if (! $order->hasStock()) {
        return ValidationResult::failed('Insufficient stock');
    }

    if (! $order->isApproved()) {
        return ValidationResult::failed('Order not approved');
    }

    return ValidationResult::passed();
}

// Caller knows exactly what failed
$result = $this->validateForProcessing($order);
if (! $result->passed()) {
    Log::warning($result->reason());
}
```
