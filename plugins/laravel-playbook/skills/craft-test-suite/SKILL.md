---
name: craft-test-suite
description: Crafting a test suite. Zero to green in 60 seconds.
---

# Skill: Craft Test Suite

> "A test suite that requires setup instructions has already failed."

## The Standard

1. **Pest + Orchestra Testbench**: Pest v4+ for tests, Orchestra Testbench for the Laravel environment. Never PHPUnit directly. Never Mockery -- Pest's built-in mocking suffices.

2. **TestCase anatomy**: Extend `Orchestra\Testbench\TestCase`. Override `getPackageProviders()`, `getEnvironmentSetUp()`, and `setUpDatabase()`. This is the foundation for every package test suite.

3. **`Pest.php` configuration**: Bind TestCase globally with `uses(TestCase::class)->in(__DIR__)`. Define custom expectations and helper functions here. One file, one source of truth.

4. **`it()` closures exclusively**: Never `test()`, never `describe()`. Natural language: `it('can create a role')`, `it('throws when filter not allowed')`.

5. **`expect()` chains**: `expect($value)->toBe($expected)`. Never `$this->assert*()`. One assertion style across the entire suite.

6. **Domain-organized directories**: Organize by concern, not by layer. `tests/Commands/`, `tests/Models/`, `tests/Middleware/`. Never `Unit/Feature/Integration`.

7. **SQLite in-memory**: Default database for all tests. Works everywhere, no Docker, no setup. Real database services only when dialect matters.

8. **TestSupport/ directory**: Test models, helpers, fixtures, resources. Keep test infrastructure separate from test assertions.

9. **`::fake()` methods on package facades**: Ship fakes so consumers can test package interactions without mocking internals. Follow the `Bus::fake()` contract: record calls, expose assertion methods. See craft-fake for the full pattern.

10. **`::test()` fluent fakes (Livewire)**: When the package ships Livewire components, use `Livewire::test()` for fluent interaction testing. The test creates the component, chains interactions, and asserts state in a single call.

11. **Architecture tests**: Minimum baseline -- no debugging functions. Layer architectural presets for deeper enforcement: strict types, final classes, dependency boundaries. Use Pest's `arch()` function with `->expect()` chains.

12. **Higher-order expectations**: Use `->each` for collection item assertions. Use property drilling (`expect($user)->name->toBe('Nuno')`) for readable nested assertions. Use `->sequence()` for ordered collection assertions.

13. **Custom expectations**: Domain-specific assertions are a feature. Register in `Pest.php` via `expect()->extend()`. Ship them in a publishable test helper file so consumers can import and reuse them.

14. **Composer scripts**: `test`, `test-coverage`, `format`, `analyse`. Every package ships with the same four commands. No guessing.

## The Anti-Patterns

| Don't                             | Do                                          | Why                                                      |
|-----------------------------------|---------------------------------------------|----------------------------------------------------------|
| PHPUnit directly                  | Pest                                        | Pest wraps PHPUnit with better DX                        |
| `Unit/Feature/Integration` dirs   | Domain directories (`Commands/`, `Models/`) | Organize by what, not by how                             |
| `$this->assertEquals()`           | `expect()->toBe()`                          | One assertion API, not two                               |
| `test('it can...')`               | `it('can...')`                              | Natural language, no redundant prefix                    |
| `describe()` blocks               | Flat file grouping                          | One concern per file, no nesting                         |
| Real database by default          | SQLite in-memory                            | Zero config, instant feedback                            |
| Helpers scattered in tests        | `TestSupport/` directory                    | Infrastructure separate from assertions                  |
| `setUp()` in test files           | `beforeEach()`                              | Pest convention, not PHPUnit ceremony                    |
| Force consumers to mock internals | Ship `::fake()` on the facade               | Mocks couple to implementation, fakes couple to behavior |
| Skip architecture tests           | Start with the baseline, layer up           | Architecture rot is silent until it isn't                |

## Real-World Examples

See [examples.md](examples.md).
