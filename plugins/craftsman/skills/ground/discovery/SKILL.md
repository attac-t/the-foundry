---
name: ground-discovery
description: Research before implementation. Reading before writing.
---

# Skill: Discovery

> "The elegant solution exists. It is waiting to be discovered."

## When

Before writing any code. Always.

## The Protocol

1. **Framework**: "How does Laravel solve this?" → Read `vendor/laravel/...`
2. **Project**: "How did we solve this elsewhere?" → `grep` the domain.
3. **Package**: "How does the package expect to be used?" → Read source.
4. **MCP**: If available, use `model-info`, `search-docs`.

## The Anti-Patterns

- **Guessing**: Assuming a method exists without verification.
- **Hallucinating**: Inventing configuration options.
- **Copy-Pasting**: Using generic examples instead of project patterns.

## The Output

State: "Discovered: [N] patterns in `Domain/X`. Using `Y` as reference."
