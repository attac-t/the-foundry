# Expectation Chains: Examples

Fluent assertions without traps.

---

## The Pattern

### Valid Chains
**Why?** Fluent, readable, correct.
```php
// Count + type
expect($restored->chapters)
    ->toHaveCount(3)
    ->each->toBeInstanceOf(Chapter::class);

// Multiple properties
expect($order)
    ->status->toBe('confirmed')
    ->total->toBeGreaterThan(0);

// Different subjects
expect($chapters)->toHaveCount(2)
    ->and($paragraphs)->toHaveCount(4);
```

---

## Common Scenarios

### The Nesting Trap
```php
// THIS DOES NOT WORK
->each->paragraphs->each->toBeInstanceOf(Paragraph::class)
```

`->each` returns a proxy allowing ONE assertion method.

### Correct Pattern for Nested Collections
```php
expect($restored->chapters)
    ->toHaveCount(2)
    ->each->toBeInstanceOf(Chapter::class);

expect($restored->chapters->first()->paragraphs)
    ->toHaveCount(2)
    ->each->toBeInstanceOf(Paragraph::class);
```

### Higher-Order Expectations
```php
expect($users)
    ->each->name->not->toBeEmpty()
    ->each->email->toContain('@');
```

| Pattern        | Usage                     |
| -------------- | ------------------------- |
| `->each->`     | Assert on each item       |
| `->sequence()` | Different values per item |
| `->first->`    | Assert on first item      |
| `->last->`     | Assert on last item       |

---

## Reference

- [Pest: Expectations](https://pestphp.com/docs/expectations)
- [Pest: Higher Order Expectations](https://pestphp.com/docs/higher-order-expectations)
