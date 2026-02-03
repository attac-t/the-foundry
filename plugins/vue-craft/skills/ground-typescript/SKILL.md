---
name: ground-typescript
description: TypeScript philosophy. Inference over annotation. Types are documentation.
---

# Skill: TypeScript

> "Types are the first draft of your documentation."

## The Standard

- **Inference over annotation**: Let TypeScript work. Don't annotate what it already knows.
- **Types as documentation**: JSDoc in interfaces. Future you will thank present you.
- **Explicit at boundaries**: Function parameters, return types, and exports are explicit. Internal code infers.
- **Absolute imports**: Use `@/` alias. Relative paths break when files move.

## The Check

Ask yourself:
- Am I annotating what TypeScript already infers?
- Would a new developer understand this type without reading the implementation?
- Are my interfaces documented with JSDoc?

## Real-World Examples

See [examples.md](examples.md).
