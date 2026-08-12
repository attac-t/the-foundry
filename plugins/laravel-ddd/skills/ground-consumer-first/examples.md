# Consumer First: Examples

> Concrete call-sites. Written before the implementations that satisfy them.

---

## Design the Consumption First

Before writing a single class in a `Refunds` domain, write the call-site you want:

```php
// The call-site you wish existed — write this first.
$refund = Refund::for($order)
    ->reason(RefundReason::Damaged)
    ->partial(Money::fromCents(2_500))
    ->issue();
```

Read it aloud. It scans as a sentence, so the shape is right. Now build what makes it true.

Compare the shape you get by starting from the implementation:

```php
// Implementation-first. Nobody wished for this.
$refund = app(RefundService::class)->processRefund(
    $order->id,
    2500,
    'damaged',
    true,
    null,
    false,
);
```

Six positional arguments, two booleans, an ID instead of a model. Every one of those
is a decision the implementation made *for* the caller. Sketching the call-site first
costs nothing; unwinding this signature costs a migration.

---

## Which Call-Site Becomes Clearer?

### An answer → keep the line

```php
// Domain/Ordering/Models/Order.php
public function isRefundable(): bool
{
    return $this->status === OrderStatus::Paid
        && $this->paid_at !== null
        && $this->refunded_at === null;
}
```

Four lines added. The caller collects the return:

```php
if ($order->isRefundable()) {
    // ...
}
```

Every future reader of every future call-site is clearer. Asset.

### No answer → delete the line

```php
// Defensive guard. Which call-site is clearer? None — the type already guarantees it.
public function issue(Order $order): Refund
{
    if (! $order instanceof Order) {
        throw new InvalidArgumentException('Expected an Order.');
    }
    // ...
}
```

```php
// Speculative parameter. No caller passes anything but the default.
public function issue(Order $order, bool $notify = true, ?Carbon $at = null): Refund
```

```php
// Pass-through wrapper. The caller could have called the real method.
public function getOrder(): Order
{
    return $this->order;
}
```

```php
// Narrating comment. It says what the next line says.
// Save the refund
$refund->save();
```

Four deletions. No call-site got worse.

---

## Return the Thing, Not a Field of It

A resolver folds several sources into one answer. Hand back the answer, not one column off it.

```php
// ❌ Answers exactly one question.
public function effectivePaymentMethodId(): ?int
{
    return $this->adjustment?->payment_method_id ?? $this->payment_method_id;
}

// ✅ Answers every question the method has.
public function effectivePaymentMethod(): ?PaymentMethod
{
    return $this->adjustment?->paymentMethod ?? $this->paymentMethod;
}
```

The first call-site wants the key and takes it either way — `->effectivePaymentMethod()?->id`.
The second wants the method's `name`, and against the `*Id()` shape must either re-query the
model it already had or add `effectivePaymentMethodName()` beside the first. Two methods now
hold the same `??` chain, and the day the rule changes, one of them is missed.

The scalar is right where no model exists to return — a bare key from a third party. Then `->id`
has nothing to hang off, and the name says so.

**The tell.** A method name ending in `Id`, `Name`, `Code` or `Amount`. Drop the suffix and read
it again: would its owner serve the call-site better?

---

## The Test Suite Is a Call-Site Too

If a domain is painful to set up in a test, it will be painful to call in production.

```php
// Painful setup is a design signal, not a testing problem.
$refund = new Refund(
    new RefundContext($order, $reason, $amount, $issuer, $policy),
    app(RefundCalculator::class),
    app(RefundGateway::class),
);

// The call-site the test wishes existed — and so does production code.
$refund = Refund::for($order)->reason($reason)->issue();
```
