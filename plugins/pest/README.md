# Pest

Pest v3 testing. This plugin knows **how to write the test**.

11 skills. `kernel:craft-test` decides *what* deserves a test; this decides how it
reads.

---

## Install

```
/plugin install pest@the-foundry
```

Pulls in [`kernel`](../kernel/README.md) automatically.

---

## Philosophy

A test is a specification. If you have to read the implementation to understand
the test, the test failed.

---

## The Split

**`kernel:craft-test`** — what to test:

```
Test behavior, not implementation
Cover the edges, not every line
Skip the obvious, test the risky
```

**`pest:craft-test`** — how to write it:

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

## Skills

```
ground-suite            What to test, what to skip
ground-prose            Tests that read like specifications
craft-test              The unit of specification
craft-organization      File layout for a large suite
craft-dataset           Same test, different inputs
craft-factory-state     A DSL for building test state
craft-expectation-chain Fluent assertions without the traps
craft-custom-expectation When to extract your own, and how
craft-arch              Structure as code
decide-mock             Real dependency or fake
polish                  Test-specific polish passes
```

Browse them in [`skills/`](skills/).

---

## License

[MIT](../../LICENSE)
