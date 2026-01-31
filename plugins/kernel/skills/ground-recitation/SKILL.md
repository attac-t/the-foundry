---
name: ground-recitation
description: Anchor yourself. Prevent context drift.
---

# Skill: Recitation

> "Constantly rewriting todo lists pushes the global plan into recent attention span." — Manus

## The Standard

- **Rewrite**: Goal, Focus, Scratchpad -- current state, not history.
- **Prune**: Remove failures when lesson internalized.
- **Reset**: Blank the file when starting a new goal.

## The Check

Ask yourself:
- Does Goal still match what I'm doing?
- Is Focus pointing to the right domain/files?
- Are stale Failures cluttering context?
- Is Progress synced with blueprint's Current task?

## How to Update

| Section     | Strategy                                       |
|-------------|------------------------------------------------|
| Goal        | Rewrite when objective changes                 |
| Constraints | Add/remove as decisions are made               |
| Focus       | Rewrite each session                           |
| Progress    | Pointer to blueprint + active task             |
| Failures    | Append new. Remove when internalized.          |
| Scratchpad  | Clear freely. Temporary.                       |

## Progress Section

Progress is a **pointer**, not a list. The list lives in `blueprint.md`.

```markdown
## Progress

See `blueprint.md` for task tracking.

Currently: [active task description]
```

Do not duplicate task checkboxes here. The blueprint is the plan.

## When to Blank

Reset to template when:
- Starting a **new goal**
- Goal is **complete**
- Context is **stale**

## Artifact Hierarchy

Memory has layers. Each artifact serves a distinct purpose.

| Artifact            | Lifespan     | Purpose        | When                     |
|---------------------|--------------|----------------|--------------------------|
| `working.md`        | Session      | Cognitive RAM  | Always active            |
| `blueprint.md`      | Goal         | Task tracking  | Multi-step work          |
| `spec.md`           | Goal         | Requirements   | New features             |
| `adr/*.md`          | Permanent    | Decisions      | Architecture choices     |
| `handoffs/*.md`     | Transitional | State transfer | Manual: `/handoff`       |
| `observations/*.md` | Permanent    | Learnings      | Manual: `/observe`       |

### Clarifying Overlaps

**Failures (working.md) vs Observations**:
- `Failures` = temporary. Remove when lesson internalized.
- `observations/` = permanent. Worth reading again later.

> Rule: If a failure taught you something worth remembering, create an observation. Then remove the failure.

Don't wait to be asked. If the work warrants an artifact, create it proactively.

## The File

`working.md` in branch memory. See `ground-topic` for path.
