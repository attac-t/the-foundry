---
name: decide-eager-loading
description: When to eager load relationships. N+1 prevention decisions.
---

# Skill: Eager Loading

> "One query is better than N+1."

## The Decision

**Use `with()` when:**
- You know upfront which relationships you need
- Building a query before execution
- Relationships will be accessed for most/all records

**Use `load()` when:**
- Model already retrieved
- Conditional loading based on runtime logic
- Adding relationships after initial query

**Use `withCount()` when:**
- Only need the count, not the related models
- Displaying "5 comments" without loading comments

## The Heuristic

Ask: *"Will I access this relationship in a loop?"*

- **Yes** → Eager load with `with()`
- **Maybe** → Consider `load()` conditionally
- **Just counting** → `withCount()`

## The Quick Test

| Scenario                    | Method              |
|-----------------------------|---------------------|
| Query time, known relations | `with()`            |
| Post-query, conditional     | `load()`            |
| Only need counts            | `withCount()`       |
| Nested relationships        | `with('a.b.c')`     |
| Constrained eager load      | `with(['a' => fn])` |

## Real-World Examples

For concrete examples from this codebase, see [examples.md](examples.md).
