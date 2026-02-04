# Decide Mock: Examples

When to mock. When to use the real thing.

---

## Mock: External Services

### Payment Gateway
**Why?** Don't hit Stripe in tests.
```php
it('processes payment', function () {
    $gateway = $this->mock(PaymentGateway::class);
    $gateway->shouldReceive('charge')
        ->with(1000, 'tok_test')
        ->andReturn(new PaymentResult(success: true));

    $result = app(ProcessPaymentAction::class)->execute(1000, 'tok_test');

    expect($result->success)->toBeTrue();
});
```

### Email Provider
**Why?** Don't send real emails.
```php
use Illuminate\Support\Facades\Mail;

it('sends welcome email', function () {
    Mail::fake();

    app(RegisterUserAction::class)->execute($data);

    Mail::assertSent(WelcomeEmail::class);
});
```

---

## Don't Mock: Database

### Use Transactions Instead
**Why?** Real queries catch real bugs.
```php
// Pest.php already wraps in transaction via RefreshDatabase

it('creates order with items', function () {
    $order = app(CreateOrderAction::class)->execute($data);

    // Real database assertions
    expect(Order::count())->toBe(1);
    expect(OrderItem::count())->toBe(2);
});
```

---

## Don't Mock: Your Own Classes

### Use Real Implementations
**Why?** Mocking your code tests nothing.
```php
// Bad: mocking your own class
it('creates order', function () {
    $calculator = $this->mock(PriceCalculator::class);
    $calculator->shouldReceive('total')->andReturn(1000);
    // Tests nothing real
});

// Good: use the real calculator
it('calculates total correctly', function () {
    $order = app(CreateOrderAction::class)->execute($data);

    expect($order->total)->toBe(2500); // Real calculation
});
```

---

## Freeze Time Instead of Mocking

### Time-Dependent Logic
**Why?** Cleaner than mocking Carbon.
```php
use Illuminate\Support\Facades\Date;

it('expires after 24 hours', function () {
    $order = Order::factory()->create();

    Date::setTestNow(now()->addHours(25));

    expect($order->fresh()->isExpired())->toBeTrue();
});
```

---

## Reference

- [Pest: Mocking](https://pestphp.com/docs/mocking)
- [Martin Fowler: Mocks Aren't Stubs](https://martinfowler.com/articles/mocksArentStubs.html)
- [Vladimir Khorikov: When to Mock](https://enterprisecraftsmanship.com/posts/when-to-mock/)
