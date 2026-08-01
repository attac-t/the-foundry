---
name: polish
description: Laravel polish. PHP/Laravel standards for each polish pass. Invoke when polishing PHP/Laravel code.
---

# Skill: Laravel Polish

> "Laravel code should read like the framework wrote it."

Seven passes. One concern each, in order — a naming issue spotted during the whitespace pass gets noted, then fixed in the naming pass. **Zero behavior change**: every test that passed before passes after. You are a copyeditor, not an author.

1. Docblocks · 2. Names · 3. Methods · 4. Framework internals · 5. Whitespace · 6. Conditionals · 7. Tests

Pairs with `kernel:polish` for the wider protocol — enumeration, reporting, team mode.

## Pass 1: Docblocks — The Craftsman Voice

**The trial**: read the method signature. Name, parameters with type-hints, return type. Does the signature tell the full story? If yes — delete the docblock.

**Survivors earn their place when they**:
- Refine types PHP can't express: `@param Collection<int, Order> $orders`
- Warn the caller: `@throws UnsupportedStateException`
- Link external docs: `@see https://stripe.com/docs/api/...`
- Clarify non-obvious constraints in one sentence

**Delete when they**:
- Restate `@param` types already in the signature
- Restate `@return` types already declared
- Say "Create a new instance" on constructors
- Narrate what the one-line body already shows
- Are longer than the method body

**Craftsman voice**: one line, present tense, verb-first. "Determine if...", "Resolve the...", "Build a...". Never "This method will...".

## Pass 2: Names — Zero Javaism

| Smell                              | Fix                                                                  |
|------------------------------------|----------------------------------------------------------------------|
| `get*()`/`set*()`                  | `lineAmount()` not `getLineAmount()`                                 |
| `*Manager`/`*Handler`/`*Processor` | What does it DO? `SyncsPayments`? `BuildsPayload`?                   |
| `*Helper`/`*Utility`               | Decompose into named methods or a trait with identity                |
| `*Interface` suffix                | `SyncableStore` — PHP doesn't need it                                |
| Over-qualified                     | In `Billing\Aggregation\`, just `BuildResult` — the namespace qualifies |
| Stuttering                         | `$config->mode` not `$syncConfig->syncMode`                          |
| Acronym casing                     | `XeroApi`, `HttpClient` — follow Laravel's `Http` convention         |

**Variables**: nouns, short, obvious. `$order`, `$transaction`, `$coverage`. No abbreviations (`$pmTotal` → `$paymentTotal`). `$item` is fine in a short closure.

## Pass 3: Methods — Return Stands Alone

When a method returns a fluent chain, `return` stands on its own line. The chain begins on the next line, reading top-to-bottom like a sentence.

**Extract when**: a blank line appears instinctively between "two things." That blank line is a method boundary.

## Pass 4: Framework Internals

| Instead Of                   | Use                                               |
|------------------------------|---------------------------------------------------|
| `foreach` + accumulator      | `Collection::sum()`, `reduce()`, `mapWithKeys()`  |
| `foreach` + filter           | `Collection::filter()`, `reject()`, `where()`     |
| `foreach` + first match      | `Collection::first()`, `sole()`, `firstWhere()`   |
| `foreach` + group            | `Collection::groupBy()`, `mapToGroups()`          |
| `foreach` + transform        | `Collection::map()`, `flatMap()`, `pluck()`       |
| Assign-then-return           | `tap($thing, fn ($t) => $t->save())`              |
| Create-modify-return         | `tap(new Thing, fn ($t) => ...)`                  |
| `array_map(fn..., $arr)`     | `collect($arr)->map(fn...)`                       |
| `!empty($x) && $x->method()` | `$x?->method()` (nullsafe)                        |
| `$val = $val ?? $default`    | `$val ??= $default`                               |
| `config('key') ?? default`   | `config('key', $default)`                         |
| `in_array($val, [...])`      | `collect([...])->contains($val)` or enum `->in()` |
| `if ($cond) { $cb(); }`      | `when($cond, $cb)` if available                   |
| `function ($x) use ($y) {…}` | `fn ($x) => …` when single-expression              |

**QueryBuilders over scopes**: dedicated builder classes, not model scopes. Each method is one clause. They compose through chaining. The model stays lean — `newEloquentBuilder()` and nothing else.

**Model states** (`spatie/laravel-model-states`): use `whereState()` and the transition API. Never assign state fields directly. Never query raw column values.

## Pass 5: Whitespace — Import Grouping

Imports grouped logically: PHP classes, then Laravel classes, then domain classes. Blank line between groups. Alphabetical within each group. No inline FQCNs — if a class appears in the body, it belongs in the imports.

Classes breathe: properties, constructor, public methods, protected methods, private methods — each group separated.

## Pass 6: Conditionals

- `match` over `switch`. Always. `match` is an expression.
- `match` over if/elseif chains when branching on a single value.
- No `!== null` / `!== false` when truthiness suffices.
- Nullsafe `?->` over null checks.

## Pass 7: Tests

Defer to `pest:polish` for Pest-specific standards.

## Linter

Run `./vendor/bin/pint` on each file after editing. Pint handles formatting. You handle meaning.

---

See [examples.md](examples.md) for concrete before/after patterns.
