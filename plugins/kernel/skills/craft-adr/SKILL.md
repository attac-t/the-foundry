---
name: craft-adr
description: Recording architectural decisions. Why we chose X over Y.
---

# Skill: Craft ADR

> "Decisions in code are temporary. Decisions in ADRs are permanent."

## The Standard

1. **Location**: `docs/adr/ADR-001-title.md`. Committed, numbered, permanent.
2. **Status**: Proposed → Accepted → Deprecated.
3. **Structure**: Context → Decision → Consequences.
4. **Rationale**: Document what was rejected and why.

## Why Not Branch Memory

Branch memory is gitignored. An ADR that survives the branch cannot live somewhere
that disappears with it, and a decision nobody can review is not a decision — it is
a note.

Draft in `.claude/memory/<branch>/` while the argument is still moving. Promote to
`docs/adr/` in the same PR as the change it justifies, so the reviewer sees the
reasoning and the code together.

## When to Record

| Record               | Don't Record      |
|----------------------|-------------------|
| Package choice       | Trivial fixes     |
| Pattern choice       | Standard CRUD     |
| Schema design        | Config changes    |
| Integration approach | Obvious decisions |

## Real-World Examples

See [examples.md](examples.md).
