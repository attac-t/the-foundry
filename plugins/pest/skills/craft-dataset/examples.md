# Datasets: Examples

Same test, different inputs.

---

## The Pattern

### Inline Dataset with Named Keys
**Why?** Failure output shows the key.
```php
it('rejects invalid emails', function (string $email) {
    expect(fn () => EmailAddress::from($email))
        ->toThrow(InvalidArgumentException::class);
})->with([
    'missing @' => ['invalid-email'],
    'missing domain' => ['user@'],
    'spaces' => ['user @domain.com'],
]);
```

---

## Common Scenarios

### Named Dataset (Shared)
```php
// tests/Datasets/Relations.php
dataset('relation_types', [
    'HasMany' => ['withChapters', 'chapters', 3],
    'HasOne'  => ['withAuthor', 'author', 1],
]);

// Usage
it('preserves relations', function (string $state, string $relation, int $count) {
    $doc = Document::factory()->{$state}()->revised()->create();
    $restored = Document::fromSnapshot($doc->snapshot());

    expect($restored->{$relation})->toHaveCount($count);
})->with('relation_types');
```

### Combining Datasets
```php
it('validates input', function (string $field, mixed $value) {
    // ...
})->with('required_fields')->with('invalid_values');
```

Creates cartesian product. Never chain more than 2 datasets.

---

## When to Use

| Scenario                        | Use Dataset?       |
|---------------------------------|--------------------|
| Many invalid inputs             | Yes                |
| Same behavior, different data   | Yes                |
| Different assertion per case    | No—explicit tests  |
| 3 cases with subtle differences | No—clarity wins    |

---

## Reference

- [Pest: Datasets](https://pestphp.com/docs/datasets)
- [Laravel Daily: PHPUnit Data Providers vs Pest Datasets](https://laraveldaily.com/post/phpunit-data-providers-and-pest-datasets)
