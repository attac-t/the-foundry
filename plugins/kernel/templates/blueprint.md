# Blueprint

> Execution ledger. User confirms completion. Always current.

---

## Status

- **Branch**: `[branch]`
- **Updated**: `[date]`
- **Phase**: Discovery | Implementation | Testing | Refinement

---

## Tasks

> Sourced from spec.md Low-Level Tasks. Owner assessed via `ground-delegation` criteria.

| # | Task | Owner | Status | Confirmed |
|---|------|-------|--------|-----------|
| 1 | [Description] | self | pending | - |

**Owner**: `self` (architect does it) | `agent` (delegated to sub-agent)

**Status**:
- `self` tasks: `pending` → `in-progress` → `done`
- `agent` tasks: `pending` → `delegated` → `in-review` → `done`
- Any task: `deferred`

**Confirmed**: User confirmation + date (e.g., `2026-01-10`) or `-`

---

## Current

> Single active task (self) or multiple delegated tasks (agent). Synced to working.md Focus.

**Task**: #[N] - [Description]

**Started**: [Date]

**Blockers**: None

---

## Delegated

> Active agent tasks. Max 3 parallel. See `ground-delegation` for briefing format.

| # | Task | Agent | Started | Status |
|---|------|-------|---------|--------|
| - | - | - | - | - |

---

## Deferred

> Tasks moved out of scope. Recorded with reason.

| # | Task | Reason | Date |
|---|------|--------|------|
| - | - | - | - |

---

## Changes

> Plan mutations. Why the blueprint evolved.

| Date | Change | Reason |
|------|--------|--------|
| - | Initial blueprint | - |

---

## Completion

> Final sign-off when all tasks addressed.

**Status**: [ ] Complete

**Signed off**: -
