---
name: craft-shared-domain
description: Crafting Shared Domain. Cross-cutting concerns namespace.
---

# Skill: Craft Shared Domain

> "Shared should be small. Large Shared means restructuring needed."

## The Standard

1. **Cross-Cutting Only**: Audit, logging, base classes—truly shared concerns.
2. **Keep Minimal**: If Shared grows large, domains need restructuring.
3. **No Business Logic**: Shared is infrastructure, not domain rules.
4. **Alternative: Support**: Use `src/Support/` for utilities instead.

## The Anti-Patterns

| ❌ Don't                    | ✅ Do                        | Why                          |
|----------------------------|-----------------------------|-----------------------------|
| Dump "common" code         | Place in owning domain      | Someone owns it             |
| Business logic in Shared   | Keep in specific domain     | Business != shared          |
| Large Shared namespace     | Split into domains          | Shared is a smell           |

## Real-World Examples

See [examples.md](examples.md).
