# Test: Examples

Patterns from Pest v3.

---

## Structure

### ✅ Describe + It
**Why?** Group by method/feature.
```php
describe('CreateOrderAction', function () {
    it('creates order with items', function () {
        // ...
    });

    it('dispatches OrderCreated event', function () {
        // ...
    });
});
```

---

## Factories

### ✅ Fluent Relationships
**Why?** Readable, type-safe setup.
```php
$order = Order::factory()
    ->for(Customer::factory())
    ->has(Item::factory()->count(3))
    ->create();
```

### ✅ States
**Why?** Named configurations.
```php
$order = Order::factory()
    ->pending()
    ->highValue()
    ->create();
```

---

## Expectations

### ✅ Fluent Assertions
```php
expect($order)
    ->status->toBe(OrderStatus::Confirmed)
    ->items->toHaveCount(3)
    ->total->cents->toBeGreaterThan(0);
```

### ✅ Exceptions
```php
expect(fn () => $action->execute($data))
    ->toThrow(InsufficientInventoryException::class);
```

---

## Feature Tests

### ✅ Controller Flow
```php
it('stores order and redirects', function () {
    $customer = Customer::factory()->create();

    $this->actingAs($customer)
        ->post('/orders', ['items' => [...]])
        ->assertRedirect('/orders/*');

    expect(Order::count())->toBe(1);
});
```
