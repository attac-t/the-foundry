---
name: ground-recitation
description: Objective anchoring. Solves context drift.
---

# Skill: Recitation

> "Constantly rewriting todo lists pushes the global plan into recent attention span." — Manus

## The File

`$CLAUDE_MEMORY_DIR/working.md` — your cognitive RAM.

Default: `.claude/memory/working.md`
Template: `templates/working.md` (in plugin)

## When to Blank

Reset working.md to the template when:

- Starting a **new goal** (different feature/bug)
- Goal is **complete** and moving to next task
- Context has become **stale** (old failures, outdated progress)

**Keep** the Failures section if lessons are still relevant.

## How to Update

From Manus: **Rewrite, don't append.**

| Section | Update Strategy |
|---------|-----------------|
| Goal | Rewrite when objective changes |
| Constraints | Add/remove as ADRs are made |
| Focus | Rewrite each session |
| Progress | Rewrite with current steps, not history |
| Failures | Append new failures. Remove when lesson is internalized. |
| Scratchpad | Clear freely. Temporary by design. |

**The key insight:** Progress should show **current steps**, not a history of completed work. Completed steps disappear. Only what remains matters.

## The Protocol

Handled automatically by hooks:

1. **SessionStart**: `remember.sh` loads working.md
2. **Stop**: `anchor.sh` echoes Goal, `recite.sh` prompts update
3. **PreCompact**: Remind to preserve Goal, Constraints, Failures

## Anti-Patterns

- **Appending forever**: Progress becomes a changelog. Rewrite it.
- **Stale failures**: Old lessons clutter context. Prune them.
- **No update**: Prompted but ignored. The file drifts from reality.
- **Manual recitation**: If you're copying content, something's wrong.
