---
name: craft-test
description: Pest v3 testing syntax. Expressive describe/it/expect patterns.
---

# Skill: Craft Test (Pest v3)

> Syntax, not philosophy. For **what** to test, see `kernel:craft-test`.

## Core Syntax

### describe() — Group Related Tests

```php
describe('CreateOrderAction', function () {
    it('creates order with valid data', function () {
        // test
    });

    it('throws when inventory insufficient', function () {
        // test
    });
});
```

### it() — Expressive Test Names

```php
// Good: reads as specification
it('dispatches OrderCreated event on success', function () {});
it('throws InsufficientInventoryException when stock depleted', function () {});

// Avoid: vague or prefixed names
test('test order creation', function () {});
it('works', function () {});
```

### expect() — Fluent Assertions

```php
// Chained assertions
expect($order)
    ->status->toBe(OrderStatus::Confirmed)
    ->items->toHaveCount(3)
    ->total->cents->toBeGreaterThan(0);

// Higher-order expectations
expect($users)->each->toBeInstanceOf(User::class);

// Exception assertions
expect(fn () => $action->execute($data))
    ->toThrow(InsufficientInventoryException::class);
```

## Common Expectations

| Expectation | Purpose |
|-------------|---------|
| `toBe($value)` | Strict equality (===) |
| `toEqual($value)` | Loose equality (==) |
| `toBeTrue()` / `toBeFalse()` | Boolean checks |
| `toBeNull()` / `toBeEmpty()` | Null/empty checks |
| `toHaveCount($n)` | Collection/array count |
| `toContain($item)` | Array contains item |
| `toMatchArray($arr)` | Partial array match |
| `toBeInstanceOf($class)` | Type checking |
| `toThrow($exception)` | Exception assertion |
| `->not->` | Negate any expectation |

## Datasets

Reusable test data. Pure Pest.

```php
dataset('invalid_emails', [
    'missing @' => ['invalid-email'],
    'missing domain' => ['user@'],
    'spaces' => ['user @domain.com'],
]);

it('rejects invalid email formats', function (string $email) {
    expect(fn () => EmailAddress::from($email))
        ->toThrow(InvalidArgumentException::class);
})->with('invalid_emails');
```

## Lifecycle

```php
describe('OrderProcessing', function () {
    beforeEach(function () {
        $this->customer = Customer::factory()->create();
    });

    it('processes order for customer', function () {
        // $this->customer available
    });
});
```

## Reference

| Pattern | Syntax |
|---------|--------|
| Group tests | `describe('Subject', fn () => ...)` |
| Single test | `it('does something', fn () => ...)` |
| Assert value | `expect($value)->toBe($expected)` |
| Assert exception | `expect(fn () => ...)->toThrow(Ex::class)` |
| Dataset | `->with('dataset_name')` |
| Skip | `->skip($condition, 'reason')` |
| Setup | `beforeEach(fn () => ...)` |

---

## Real-World Examples

See [examples.md](examples.md) for factory patterns, feature tests, and advanced assertions.

For arch testing, type coverage, and advanced features: [pestphp.com/docs](https://pestphp.com/docs)
