# Custom Expectations: Examples

When and how to extract.

---

## The Pattern

### Basic Custom Expectation
**Why?** DRY repeated assertions.
```php
// tests/Expectations.php
expect()->extend('toHydrateCorrectly', function () {
    $restored = Document::fromSnapshot($this->value->snapshot());

    expect($restored->getAttributes())
        ->toEqual($this->value->getAttributes());

    return $this;
});

// Usage
expect($document)->toHydrateCorrectly();
```

---

## Common Scenarios

### Access the Value
```php
expect()->extend('toBeValidEmail', function () {
    $email = $this->value;

    expect(filter_var($email, FILTER_VALIDATE_EMAIL))
        ->not->toBeFalse();

    return $this;
});
```

### With Parameters
```php
expect()->extend('toHaveStatus', function (string $expected) {
    expect($this->value->status)->toBe($expected);

    return $this;
});

// Usage
expect($order)->toHaveStatus('confirmed');
```

### Chaining
```php
expect($user)
    ->toBeValidEmail()
    ->not->toBeEmpty();
```

---

## When to Extract

| Scenario                       | Extract? |
|--------------------------------|----------|
| Same assertion 3+ times        | Yes      |
| Complex multi-step assertion   | Yes      |
| Single-use complex assertion   | No       |
| Built-in exists                | No       |

---

## Reference

- [Pest: Custom Expectations](https://pestphp.com/docs/custom-expectations)
- [spatie/pest-expectations](https://github.com/spatie/pest-expectations)
