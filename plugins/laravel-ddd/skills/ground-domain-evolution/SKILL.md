---
name: ground-domain-evolution
description: Domain evolution. Refactor structure as understanding deepens.
---

# Skill: Domain Evolution

> "Don't fear changes—iteration is healthy."

## The Standard

- **Domains Change**: Your first structure won't be your last.
- **Refactor Without Fear**: Good tests enable structural changes.
- **Split When Large**: A growing domain means multiple domains.
- **Merge When Tiny**: Too granular = too much overhead.

## The Check

Ask yourself:
- Has this domain grown beyond its original purpose?
- Are there 2+ distinct concepts sharing a namespace?
- Is this domain so small it's just ceremony?
- Has my understanding of the business changed?

## The Protocol

1. **Start Coarse**: Begin with fewer, larger domains.
2. **Observe Pain**: Note when a domain feels "off".
3. **Split Deliberately**: Extract sub-domain when clear boundary emerges.
4. **Document Why**: ADR the restructure decision.

## Real-World Examples

See [examples.md](examples.md).
