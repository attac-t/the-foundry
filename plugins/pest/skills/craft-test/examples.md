# Craft Test: Examples

The unit of specification.

---

## The Pattern

### Arrange-Act-Assert
**Why?** Clear phases, clear intent.
```php
it('activates user on email verification', function () {
    // Arrange
    $user = User::factory()->unverified()->create();

    // Act
    $user->markEmailAsVerified();

    // Assert
    expect($user->is_active)->toBeTrue();
});
```

---

## Anti-Patterns

### Testing Implementation (Fragile)
```php
// Bad: coupled to HOW it's done
it('calls the repository save method', function () {
    $repo = Mockery::mock(OrderRepository::class);
    $repo->shouldReceive('save')->once();
    // ...
});

// Good: tests WHAT it does
it('persists the order', function () {
    $action->execute($data);
    expect(Order::count())->toBe(1);
});
```

### Multiple Acts (Confusing)
```php
// Bad: two behaviors, one test
it('creates and activates user', function () {
    $user = User::factory()->create();
    $user->activate();
    expect($user->exists)->toBeTrue();
    expect($user->is_active)->toBeTrue();
});

// Good: split
it('creates user', function () { /* ... */ });
it('activates user', function () { /* ... */ });
```

### Testing the Framework (Waste)
```php
// Bad: Laravel already tests this
it('saves the model', function () {
    $user = User::factory()->create();
    expect($user->exists)->toBeTrue();
});

// Good: tests YOUR logic
it('hashes password on creation', function () {
    $user = User::factory()->create(['password' => 'secret']);
    expect(Hash::check('secret', $user->password))->toBeTrue();
});
```

---

## Syntax Reference

### describe() — Group Related Tests
```php
describe('CreateOrderAction', function () {
    it('creates order with valid data', function () {});
    it('throws when inventory insufficient', function () {});
});
```

### it() vs test()
```php
// it() prefixes with "it" — reads as prose
it('dispatches OrderCreated event on success', function () {});

// test() for when "it" doesn't fit
test('guest cannot access dashboard', function () {});
```

### expect() — Fluent Assertions
```php
expect($order)
    ->status->toBe(OrderStatus::Confirmed)
    ->items->toHaveCount(3)
    ->total->cents->toBeGreaterThan(0);

// Exception
expect(fn () => $action->execute($data))
    ->toThrow(InsufficientInventoryException::class);
```

### Lifecycle Hooks
```php
beforeEach(function () {
    $this->user = User::factory()->create();
});

afterEach(function () {
    // cleanup
});
```

---

## Common Expectations

| Expectation                    | Purpose                |
|--------------------------------|------------------------|
| `toBe($value)`                 | Strict equality (===)  |
| `toEqual($value)`              | Loose equality (==)    |
| `toBeTrue()` / `toBeFalse()`   | Boolean checks         |
| `toBeNull()` / `toBeEmpty()`   | Null/empty checks      |
| `toHaveCount($n)`              | Collection/array count |
| `toContain($item)`             | Array contains         |
| `toMatchArray($arr)`           | Partial array match    |
| `toBeInstanceOf($class)`       | Type checking          |
| `toThrow($exception)`          | Exception assertion    |
| `->not->`                      | Negate any expectation |

---

## Action Testing

### Testing Actions with DTOs
```php
describe('CreateOrderAction', function () {
    beforeEach(function () {
        $this->action = app(CreateOrderAction::class);
        $this->customer = Customer::factory()->create();
    });

    it('creates order from valid data', function () {
        $data = new CreateOrderData(
            customerId: $this->customer->id,
            items: [
                new OrderItemData(productId: 1, quantity: 2, price: 1000),
            ],
        );

        $order = $this->action->execute($data);

        expect($order)
            ->toBeInstanceOf(Order::class)
            ->customer_id->toBe($this->customer->id)
            ->items->toHaveCount(1);
    });

    it('throws when customer not found', function () {
        $data = new CreateOrderData(customerId: 99999, items: []);

        expect(fn () => $this->action->execute($data))
            ->toThrow(CustomerNotFoundException::class);
    });
});
```

### Testing Events
```php
use Illuminate\Support\Facades\Event;

it('dispatches OrderConfirmed event', function () {
    Event::fake([OrderConfirmed::class]);

    $order = Order::factory()->pending()->create();
    app(ConfirmOrderAction::class)->execute($order);

    Event::assertDispatched(OrderConfirmed::class, function ($event) use ($order) {
        return $event->order->id === $order->id;
    });
});
```

---

## Feature Tests

### Controller Happy Path
```php
describe('POST /orders', function () {
    beforeEach(function () {
        $this->customer = Customer::factory()->create();
        $this->product = Product::factory()->create(['price' => 1000]);
    });

    it('creates order and redirects', function () {
        $response = $this->actingAs($this->customer)
            ->post('/orders', [
                'items' => [
                    ['product_id' => $this->product->id, 'quantity' => 2],
                ],
            ]);

        $response->assertRedirect('/orders');
        $this->assertDatabaseHas('orders', [
            'customer_id' => $this->customer->id,
        ]);
    });
});
```

### API Responses
```php
describe('GET /api/orders', function () {
    it('returns paginated orders', function () {
        $customer = Customer::factory()
            ->has(Order::factory()->count(15))
            ->create();

        $response = $this->actingAs($customer, 'sanctum')
            ->getJson('/api/orders');

        $response
            ->assertOk()
            ->assertJsonCount(10, 'data')
            ->assertJsonPath('meta.total', 15);
    });
});
```

---

## Reference

- [Pest: Writing Tests](https://pestphp.com/docs/writing-tests)
- [Pest: Expectations](https://pestphp.com/docs/expectations)
- [Ian Cooper: TDD Where Did It All Go Wrong](https://keyvanakbary.github.io/learning-notes/talks/tdd-where-did-it-all-go-wrong/)
- [Vladimir Khorikov: Unit Testing Principles](https://enterprisecraftsmanship.com/book/)
