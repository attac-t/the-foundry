# Laravel DDD

Opinionated Laravel patterns for domain-driven design.

This plugin knows **what to build** and **when to use it**. The kernel knows how to think. This knows how to code Laravel.

---

## Philosophy

Controllers don't do work. Actions do. Models own their behavior. DTOs carry data. Fail fast at boundaries.

Every pattern exists for a reason. Every decision has a heuristic.

---

## Grounding

When you enter Laravel context, Claude activates `ground-laravel` — the Laravel philosophy:

```
Convention over configuration     Follow defaults. Custom only when necessary.
Eloquent as truth                 Don't abstract around the ORM.
Thin controllers                  Controllers route. Actions execute.
Batteries included                Laravel first. Spatie second. Custom last.
Named parameters                  2+ args? Name them. Closures too.
```

This happens automatically via the kernel's `evaluate.sh`. No manual invocation needed.

---

## What You Get

```
Thin controllers      Traffic cops, not business logic
Pure actions          One public method, one responsibility
Typed DTOs            Spatie Laravel Data v4
Smart models          Eloquent as source of truth
Clean queries         QueryBuilder classes over scopes
Defensive code        Fail fast, guard clauses, null objects
```

---

## Skills

47 skills. Three types.

```
ground-*     Philosophy and mindset (8 skills)
craft-*      How to build (22 skills)
decide-*     When to use what (16 skills)
```

### Highlights

```
craft-action         Single-purpose Actions, not service sprawl
craft-concern        Thin traits — delegate to builders, collections, actions
craft-dto            Spatie Laravel Data v4 value objects
craft-model-state    Explicit states over boolean flags
craft-guard-clause   Handle bad cases first
decide-extraction    When to extract to Action class
decide-events        Events vs direct calls
```

Run `/skills laravel-ddd` to see all.

---

## Installation

Standalone.

```
/plugin marketplace add attac-t/the-foundry
/plugin install laravel-ddd@the-foundry
```

Pairs well with `kernel` for cognitive patterns — optional, not required.

```
/plugin install kernel@the-foundry
```

---

## Recommended Packages

The skills assume these are installed:

```
spatie/laravel-data           DTOs
spatie/laravel-model-states   State machines
```

---

## License

MIT
