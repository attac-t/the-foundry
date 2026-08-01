---
name: decide-chunking
description: When and how to process large datasets. Memory-efficient iteration.
---

# Skill: Chunking

> "Memory is finite. Chunk accordingly."

## The Decision

**Use `chunk()` when:**
- Processing large datasets that won't fit in memory
- Callback doesn't modify records being iterated
- Order doesn't matter or you're ordering by non-modified column

**Use `chunkById()` when:**
- Callback modifies records (updates/deletes)
- Need consistent ordering during iteration
- Avoiding offset performance issues

**Use `cursor()` / `lazy()` when:**
- Read-only iteration
- Need generator-style streaming
- Memory is critical (exports, reports)

## The Heuristic

Ask: *"Am I modifying records during iteration?"*

- **Yes** → `chunkById()`
- **No, need callback** → `chunk()`
- **No, just streaming** → `cursor()`

## The Quick Test

| Scenario                   | Method        |
|----------------------------|---------------|
| Batch update/delete        | `chunkById()` |
| Read + process in callback | `chunk()`     |
| Export to file             | `cursor()`    |
| Memory-critical streaming  | `lazyById()`  |

## The Anti-Patterns

| ❌ Don't                                | ✅ Do                              | Why                                              |
|----------------------------------------|-----------------------------------|--------------------------------------------------|
| Break a chain into a temp per stage "for memory" | Break a chain only for readability | Every temp stays pinned for the scope's lifetime — measurably the *worst* variant, not the fix |

Break a chain for readability, never for memory. The memory lever is eager-vs-lazy — `lazy()`, `cursor()`, a builder chain — not syntax.

## Real-World Examples

For concrete examples from this codebase, see [examples.md](examples.md).
