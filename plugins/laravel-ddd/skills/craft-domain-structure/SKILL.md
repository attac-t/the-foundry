---
name: craft-domain-structure
description: Crafting Domain Structure. Mini-Laravel-app per domain.
---

# Skill: Craft Domain Structure

> "Each domain is a mini-Laravel app with its own internal structure."

## The Standard

1. **Consistent Structure**: Every domain follows the same internal layout.
2. **Actions First**: Actions are the primary entry point to domain logic.
3. **Models Close**: Model, states, query builder—co-located.
4. **Events Explicit**: Domain events in `Events/`, not generic Laravel events.

## The Anti-Patterns

| ❌ Don't                | ✅ Do                   | Why                |
| ---------------------- | ---------------------- | ------------------ |
| Flat domain folder     | Organized subfolders   | Findable, scalable |
| Inconsistent structure | Same layout everywhere | Predictable        |
| Services folder        | Actions folder         | Clear naming       |
| Global events          | Domain-specific events | Bounded context    |

## Real-World Examples

See [examples.md](examples.md).
