# Organization: Examples

File structure patterns for large suites.

---

## The Pattern

### Standard Layout
**Why?** Each file has one job.
```
tests/
├── Pest.php              # Config, base class, uses()
├── Expectations.php      # Custom expectations
├── Helpers.php           # Custom helper functions
├── Datasets/
│   └── Relations.php     # Shared test data
├── Feature/
│   ├── SnapshotTest.php
│   ├── TimeTravelTest.php
│   └── ImmutabilityTest.php
└── Unit/
```

---

## Common Scenarios

### Folder-Based Groups
```php
// tests/Pest.php
pest()->extend(TestCase::class)
    ->group('feature')
    ->in('Feature');
```

### File-Level Groups
```php
// tests/Feature/SnapshotTest.php
pest()->group('snapshot');

it('preserves state', function () {});
it('handles relations', function () {});
```

### Slow Test Isolation
```php
it('processes large dataset', function () {
    // expensive operation
})->group('slow');
```

```bash
./vendor/bin/pest --exclude-group=slow  # fast feedback
./vendor/bin/pest --group=slow          # CI only
```

### Multiple Groups
```php
it('syncs with external API', function () {
    // ...
})->group('integration', 'slow');
```

---

## Reference

- [Pest: Configuring Tests](https://pestphp.com/docs/configuring-tests)
- [Pest: Grouping Tests](https://pestphp.com/docs/grouping-tests)
- [Pest: Optimizing Tests](https://pestphp.com/docs/optimizing-tests)
