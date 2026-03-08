---
name: polish
description: Pest polish. Test-specific standards for each polish pass. Invoke when polishing Pest test files.
---

# Skill: Pest Polish

> "Tests are specifications. Polish them like production code."

This extends `kernel:polish` with Pest-specific standards. Primarily Pass 7, but all passes apply to test files.

## Pass 7: Tests — Specification Grade

### `it()` Descriptions Are Requirements

Present tense. No "should." No "correctly handles." No "tests that."

```php
// Requirement
it('syncs only the receipted portion')
it('rejects negative quantities')
it('calculates total from line items')

// Narration — fix these
it('should correctly handle the split payment case')
it('tests that the sync works properly')
```

### ~8 Lines Max

Arrange (builder chain) → Act (one call) → Assert (one expectation).

If longer, the helpers aren't absorbing enough.

### No Raw Factory Calls

The arrange phase uses builders or helper methods, not raw factory chains.

### Domain Assertions Over Raw

`$order->assertTotal(50_00)` — not `expect($response->json('data.total'))->toBe(50_00)`.

### `describe()` Blocks Name Concerns

```php
// Concerns
describe('split-item orders', function () { ... });
describe('partial payments', function () { ... });

// Categories — fix these
describe('edge cases', function () { ... });
describe('regression tests', function () { ... });
```

### Boring Variable Names

`$order`, `$result`, `$coverage`. Not `$splitItemOrderWithPartialFiscalCoverage`.

---

See [examples.md](examples.md) for full before/after test polish patterns.
