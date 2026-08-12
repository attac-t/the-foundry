---
name: ground-consumer-first
description: Consumer-first design. Shape the call-site before the implementation.
---

# Skill: Consumer First

> "Write the call-site you wish existed. Then make it true."

## The Standard

- **Consumption before implementation**: Before building a domain, write the code that will call it. If it doesn't read well, the shape is wrong — fix it while there is nothing to refactor.
- **Less code is better code, with one exception**: Every internal line is a liability. A line that makes a *call-site* clearer is an asset.
- **The call-site is the product**: Your domain has one consumer before it has a hundred. Design for them, not for the implementation.
- **Return the thing, not a field of it**: `owner()`, never `ownerId()`. The caller who wants the key writes `->id`; the caller who wants anything else is not sent back for a second method.

## The Check

Of every line you are tempted to keep, ask:

> **Which call-site becomes clearer because this line exists?**

- **An answer** → DX surface. Keep it. Named predicates, query scopes, expressive fluent methods.
- **No answer** → liability. Delete it. Defensive guards, speculative parameters, pass-through wrappers, narrating comments.

This is why extracting a condition into a named predicate is correct even though it *adds* lines. The `if` now reads as a sentence. The line was bought, not spent.

## The Anti-Patterns

| ❌ Don't                                        | ✅ Do                                          | Why                                              |
|------------------------------------------------|------------------------------------------------|--------------------------------------------------|
| Build the domain, then find the call-site ugly | Sketch the call-site first, then satisfy it    | Reshaping is expensive; sketching is free        |
| Delete a named predicate to "save a line"      | Keep it — the caller reads as a sentence       | It is DX surface, not internal weight            |
| Add a parameter "in case someone needs it"     | Add it when a call-site needs it               | No caller is clearer for it today                |
| Wrap a method to "keep the API consistent"     | Let the caller use the real method             | A pass-through answers the question with silence |
| Return an id from a resolver                   | Return the model; the caller takes `->id`      | One question answered, the rest hidden           |

## Real-World Examples

See [examples.md](examples.md).
