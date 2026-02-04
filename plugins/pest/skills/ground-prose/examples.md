# Prose Patterns: Examples

Tests that read like specifications.

---

## Test Names

### Complete Sentences
**Why?** The name IS the spec.
```php
// Bad: vague
it('works', function () {});
it('test snapshot', function () {});
it('returns state at specific revision', function () {}); // too technical

// Good: prose
it('preserves chapters through round-trip', function () {});
it('remembers the original title', function () {});
it('guards snapshots against modification', function () {});
```

---

## Full Path as Prose

### File + Describe + It
**Why?** The hierarchy tells the story.
```
Snapshots → Relations → preserves chapters through round-trip
Time Travel → at() → remembers the original title
Immutability → guards snapshots against modification
```

```php
// SnapshotTest.php
describe('Relations', function () {
    it('preserves chapters through round-trip', function () {});
});

// TimeTravelTest.php
describe('at()', function () {
    it('remembers the original title', function () {});
});
```

---

## Setup Readability

### Two-Line Rule
**Why?** Dense chains hide intent.
```php
// Bad: dense inline
$snapshot = Document::fromSnapshot(
    Document::factory()->revised()->create()->snapshot()
);

// Good: breathe
$doc = Document::factory()->revised()->create();
$snapshot = Document::fromSnapshot($doc->snapshot());
```

---

## Describe Blocks

### When to Use
**Why?** Group related, not everything.
```php
// Good: logical grouping
describe('Time Travel', function () {
    describe('at()', function () {
        it('remembers the original title', function () {});
    });

    describe('restore()', function () {
        it('brings back the original state', function () {});
    });
});

// Bad: single test, over-structured
describe('Document', function () {
    describe('creation', function () {
        it('creates', function () {}); // just use it() at top level
    });
});
```

---

## Reference

- [Pest: Writing Tests](https://pestphp.com/docs/writing-tests)
- [Pest: Grouping Tests](https://pestphp.com/docs/grouping-tests)
- [Martin Fowler: Given-When-Then](https://martinfowler.com/bliki/GivenWhenThen.html)
