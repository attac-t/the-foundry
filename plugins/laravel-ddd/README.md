# Laravel DDD

Opinionated Laravel patterns for domain-driven design.

This package knows **what to build** and **when to use it**. The kernel knows how to think. This knows how to code Laravel.

---

## Philosophy

Controllers don't do work. Actions do. Models own their behavior. DTOs carry data. QueryBuilders encapsulate queries.

Every pattern exists for a reason. Every decision has a heuristic.

---

## Grounding

When you enter Laravel context, Claude activates `ground-laravel` — the Laravel philosophy:

```
Convention over configuration     Follow defaults. Custom only when necessary.
Eloquent as truth                 Don't abstract around the ORM.
Thin controllers                  Controllers route. Actions execute.
Batteries included                Laravel first. Spatie second. Custom last.
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
```

---

## Skills

### Domain — Building Blocks

```
action         Single-purpose Actions, not service sprawl
controller     CRUDDY controllers, thin and delegating
model          Eloquent model as source of truth
dto            Spatie Laravel Data v4 value objects
query          Custom QueryBuilder classes
collection     Domain-specific collection methods
support        Cross-cutting concerns (no domain logic)
model-state    Spatie State Machine for explicit states
```

### Decide — When to Use What

```
extraction     When to extract to Action class
events         Events vs direct calls
queuing        Queue vs synchronous execution
pipelines      Pipeline vs sequential logic
casts          Cast vs Accessor
eager-loading  with() vs load()
chunking       Memory-efficient iteration
namespacing    Support vs Domain placement
composition    Trait+Interface vs Abstract
builder        Fluent Builder pattern
registry       Runtime extensibility
```

---

## Prerequisites

Requires `craftsman/kernel` for cognitive patterns.

```bash
claude plugins add craftsman/kernel
claude plugins add craftsman/laravel-ddd
```

---

## The Pattern

Every `decide-*` skill follows the same structure:

1. **The Question**: What problem are you solving?
2. **The Heuristics**: Decision matrix for when to use what
3. **The Examples**: Concrete Laravel code

Example from `decide-extraction`:

```
Extract to Action when:
- Logic appears in multiple controllers
- Logic requires testing in isolation
- The operation has a clear name

Keep inline when:
- One-liner CRUD
- Controller-specific presentation logic
```

---

## Recommended Packages

The skills assume these are installed:

```
spatie/laravel-data       DTOs
spatie/laravel-model-states   State machines
```

---

## License

MIT
