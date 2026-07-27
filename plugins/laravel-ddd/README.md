# Laravel DDD

Domain-driven design for Laravel. This plugin knows **what to build** and **when
to use it**.

46 skills, extracted from production and from *Laravel Beyond CRUD*.

---

## Install

```
/plugin install laravel-ddd@the-foundry
```

Pulls in [`kernel`](../kernel/README.md) automatically.

---

## Philosophy

Controllers don't do work — Actions do. Models own their behavior. DTOs carry
data. Fail fast at the boundary.

Every pattern earns its place. Every choice has a heuristic behind it.

When a task enters Laravel context, `ground-laravel` activates on its own:

```
Convention over configuration     Follow defaults. Customize only with cause.
Eloquent as truth                 Don't abstract around the ORM.
Thin controllers                  Controllers route. Actions execute.
Batteries included                Laravel first. Spatie second. Custom last.
Named parameters                  2+ args? Name them. Closures too.
```

---

## What You Get

```
Thin controllers      Traffic cops, not business logic
Pure actions          One public method, one responsibility
Typed DTOs            Spatie Laravel Data v4
Smart models          Eloquent as the source of truth
Clean queries         QueryBuilder classes over scope soup
Defensive code        Guard clauses, null objects, fail fast
```

---

## Skills

```
ground-*     Philosophy and mindset    7
craft-*      How to build             22
decide-*     When to use what         16
polish       Laravel polish passes     1
```

Worth knowing about:

```
craft-action         Single-purpose Actions, not service sprawl
craft-concern        Thin traits — delegate to builders, collections, actions
craft-dto            Spatie Laravel Data v4 value objects
craft-model-state    Explicit states over boolean flags
craft-guard-clause   Handle the bad case first, then return
decide-extraction    When code earns its own Action class
decide-events        Events versus a direct call
decide-dto-vs-array  Where the type-safety line sits
```

Browse all of them in [`skills/`](skills/).

---

## Assumed Packages

The skills are written against these:

```
spatie/laravel-data           DTOs
spatie/laravel-model-states   State machines
```

Neither is required to install the plugin — only to follow the patterns that use
them.

---

## License

[MIT](../../LICENSE)
