# Pest

Pest v3 testing syntax.

**Written against Pest 3. Checked 4 September 2026, when Pest was at v5.1.3** — two major versions
on. That date records a look at the package index, never a promise this is still right;
[ask it again](../../CONTRIBUTING.md#is-a-stack-plugin-still-current) before you lean on the date.

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

Standalone.

```
/plugin marketplace add attac-t/the-foundry
/plugin install pest@the-foundry
```

Pairs well with `kernel` for testing philosophy (`craft-test`) — optional, not required.

```
/plugin install kernel@the-foundry
```

---

## The Split

**What to test** — `pest:ground-suite` (`kernel:craft-test` goes deeper, when installed)

```
Test behavior, not implementation
Cover the edges, not every line
Skip the obvious, test the risky
```

**How to write it** — `pest:craft-test`

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
