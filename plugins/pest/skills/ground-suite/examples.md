# Suite Philosophy: Examples

What to test. What to skip.

---

## Don't Test the Framework

### Eloquent Persistence
**Why?** Laravel already tests this.
```php
// Bad: testing Eloquent
it('saves the model', function () {
    $user = User::factory()->create();
    expect($user->exists)->toBeTrue();
});

// Good: testing YOUR logic
it('activates user on email verification', function () {
    $user = User::factory()->unverified()->create();
    $user->markEmailAsVerified();
    expect($user->is_active)->toBeTrue();
});
```

### Factory Creates Models
**Why?** That's what factories do.
```php
// Bad: testing factory
it('creates a user', function () {
    $user = User::factory()->create();
    expect($user)->toBeInstanceOf(User::class);
});

// Good: testing factory STATE
it('creates unverified user by default', function () {
    $user = User::factory()->create();
    expect($user->hasVerifiedEmail())->toBeFalse();
});
```

---

## The Four Pillars in Action

### Protection: Catches Real Bugs
```php
// Good: catches actual defect
it('calculates discount correctly', function () {
    $order = Order::factory()->create(['subtotal' => 1000]);
    $order->applyDiscount(percent: 10);

    expect($order->total)->toBe(900);
});
```

### Resistance: Survives Refactoring
```php
// Bad: breaks when you change implementation
it('calls calculateTotal method', function () {
    $order = $this->spy(Order::class);
    $order->shouldHaveReceived('calculateTotal');
});

// Good: tests outcome, not mechanism
it('has correct total after items added', function () {
    $order = Order::factory()->withItems(3)->create();
    expect($order->total)->toBeGreaterThan(0);
});
```

---

## Zero Overlap

### Capability Over Shape
**Why?** Adding models shouldn't explode test count.
```php
// Bad: by model (N tests per model)
ChapterSnapshotTest.php   // duplicates snapshot assertions
AuthorSnapshotTest.php    // duplicates snapshot assertions

// Good: by capability (1 test with dataset)
SnapshotTest.php
it('preserves relations through round-trip', function (string $factoryState, string $relation) {
    $doc = Document::factory()->{$factoryState}()->create();
    $restored = Document::fromSnapshot($doc->snapshot());

    expect($restored->{$relation})->toHaveCount($doc->{$relation}->count());
})->with('relation_types');
```

---

## The Mini-App Principle

### Test Suite as DSL
**Why?** Setup should read like prose.
```php
// The test suite has its own language:
// - Factories → build state
// - Custom expectations → assert domain concepts
// - Datasets → input variations

$doc = Document::factory()
    ->titled('Draft')
    ->withChapters(3)
    ->revised()
    ->create();

expect($doc)->toHydrateCorrectly();
```

---

## Reference

- [Vladimir Khorikov: Four Pillars](https://enterprisecraftsmanship.com/book/)
- [Ian Cooper: TDD Where Did It All Go Wrong](https://keyvanakbary.github.io/learning-notes/talks/tdd-where-did-it-all-go-wrong/)
- [Pest: Writing Tests](https://pestphp.com/docs/writing-tests)
- [Big Nerd Ranch: Don't Test the Framework](https://bignerdranch.com/blog/what-does-dont-test-the-framework-mean/)
