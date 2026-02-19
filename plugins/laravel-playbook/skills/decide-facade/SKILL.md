---
name: decide-facade
description: When to use Facade vs Trait vs Static Factory vs Helper vs Manager. Five API entry point patterns.
---

# Skill: API Entry Point

> "Where does the developer think about this concept?"

## The Decision

**Facade when:**
- Global service to interact with (cache operations, logging, response caching)
- Package provides a standalone service, not model-level behavior
- Testability via `Facade::fake()` is valuable
- Class-based accessor (modern): `return MyService::class`

**Trait when:**
- Behavior attaches to models (`HasRoles`, `InteractsWithMedia`, `Searchable`, `Billable`)
- Integration at the Eloquent level
- Developer expects `$model->doSomething()`
- The most natural entry point across the ecosystem -- Spatie, Taylor, and community packages all reach for traits when behavior belongs on a model

**Static factory when:**
- Builder-style API: `QueryBuilder::for(Model::class)`
- Value object creation: `AllowedFilter::exact('name')`
- Entry point to a fluent chain
- `::make()` variation for schema builders (Filament's declarative UI pattern)

**Manager when:**
- Package supports multiple drivers or implementations
- The `Cache::driver('redis')`, `Scout::engine('meilisearch')` pattern
- Users need to register custom drivers via `extend()`
- Default driver resolves from config, `__call` delegates to it

**Helper function when:**
- Universal convenience: `activity()`, `route()`
- Very common operation, used everywhere
- Use sparingly -- 1-2 helpers per package max

## The Heuristic

Ask: *"Where does the developer think about this concept?"*

Model-level thinking -> trait. Global service -> facade. Builder/chain -> static factory. Multiple backends -> manager. Everywhere -> helper.

## The Quick Test

| Ask                                           | Answer | Use             |
|-----------------------------------------------|--------|-----------------|
| Does it attach to a model?                    | Yes    | Trait           |
| Is it a global, stateful service?             | Yes    | Facade          |
| Does it start a fluent chain?                 | Yes    | Static factory  |
| Does it support multiple drivers/backends?    | Yes    | Manager         |
| Is it called from everywhere, constantly?     | Yes    | Helper function |
| Does `$model->doSomething()` feel natural?    | Yes    | Trait           |
| Does `MyService::doSomething()` feel natural? | Yes    | Facade          |
| Does `MyPackage::driver('x')` feel natural?   | Yes    | Manager         |

## Real-World Examples

See [examples.md](examples.md).
