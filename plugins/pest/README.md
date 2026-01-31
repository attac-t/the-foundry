# Pest

Pest v3 testing syntax.

The kernel tells you **what to test**. This tells you **how to write it**.

---

## Philosophy

Tests should read like specifications. If you need to read the implementation to understand the test, the test failed.

---

## What You Get

```
describe()     Group related tests by behavior
it()           Expressive test names in plain English
expect()       Fluent assertions that read naturally
```

---

## Installation

Requires `kernel` for testing philosophy (`craft-test`).

```
/plugin install kernel@the-foundry
/plugin install pest@the-foundry
```

---

## The Split

**Kernel (`kernel:craft-test`)**: What to test

```
Test behavior, not implementation
Cover the edges, not every line
Skip the obvious, test the risky
```

**Pest (`pest:craft-test`)**: How to write it

```php
describe('Order creation', function () {
    it('calculates total from line items', function () {
        $order = Order::create([
            'items' => [
                ['price' => 100, 'quantity' => 2],
                ['price' => 50, 'quantity' => 1],
            ],
        ]);

        expect($order->total)->toBe(250);
    });

    it('rejects negative quantities', function () {
        expect(fn () => Order::create([
            'items' => [['price' => 100, 'quantity' => -1]],
        ]))->toThrow(InvalidQuantityException::class);
    });
});
```

---

## License

MIT
