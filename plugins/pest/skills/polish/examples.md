# Pest Polish: Examples

Before/after patterns for test polish.

---

## Test Shortening

### Raw Factory to Builder
**Why?** Tests should read like specs, not infrastructure.

```php
// Before — 14 lines of infrastructure
it('calculates the order total', function () {
    $order = Order::factory()
        ->state(['currency' => 'EUR'])
        ->afterCreating(function (Order $order) {
            LineItem::factory()
                ->for($order)
                ->state(['price' => 25_00, 'quantity' => 2])
                ->create();
            Payment::factory()
                ->for($order)
                ->state(['amount' => 50_00, 'method' => 'card'])
                ->create();
        })
        ->create();

    $result = CalculateTotal::execute($order);

    expect($result->total)->toBe(50_00);
});

// After — 7 lines of specification
it('calculates the order total', function () {
    $order = order()
        ->withItem(price: 25_00, quantity: 2)
        ->withPayment(amount: 50_00, method: 'card')
        ->create();

    $result = CalculateTotal::execute($order);

    expect($result->total)->toBe(50_00);
});
```

---

## Describe Blocks

### Category to Concern
**Why?** Categories tell you nothing. Concerns tell you what behavior is being tested.

```php
// Before — categories
describe('edge cases', function () {
    it('handles empty orders');
    it('handles split payments');
    it('handles refunds');
});

// After — concerns
describe('empty orders', function () {
    it('returns zero total');
    it('skips invoice generation');
});

describe('split payments', function () {
    it('allocates across payment methods');
    it('preserves per-method totals');
});
```

---

## Domain Assertions

### Raw to Domain
**Why?** Domain assertions document WHAT you're checking, not WHERE the data lives.

```php
// Before — raw
expect($response->json('data.total'))->toBe(50_00);
expect($response->json('data.items'))->toHaveCount(3);
expect($response->json('data.status'))->toBe('paid');

// After — domain
$order->assertTotal(50_00);
$order->assertItemCount(3);
$order->assertStatus('paid');
```

---

## it() Descriptions

### Narration to Requirement
**Why?** Requirements read like specs. Narration reads like commentary.

```php
// Before
it('should correctly calculate the total when there are multiple items')
it('tests that the discount is properly applied')
it('verifies the refund process handles partial amounts')

// After
it('calculates total from multiple items')
it('applies the discount')
it('refunds partial amounts')
```
