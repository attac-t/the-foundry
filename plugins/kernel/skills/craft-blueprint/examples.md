# Examples: Blueprint

> Real-world patterns for task tracking with user confirmation.

---

## Creating a Blueprint

```
User: Execute the spec

Claude: *reads $MEMORY_DIR/spec.md*

Creating blueprint.

| # | Task | Status | Confirmed |
|---|------|--------|-----------|
| 1 | Create User resource with authentication | in-progress | - |
| 2 | Add authentication flow handler | pending | - |
| 3 | Create request validation layer | pending | - |
| 4 | Write verification tests | pending | - |
| 5 | Update config and routing | pending | - |

Starting Task #1.
```

---

## Requesting Confirmation

```
Claude: Task #1 complete.
        - Created User resource
        - Added authentication capability
        - Configured visible and hidden fields

        Confirm to mark done?

User: confirmed

Claude: Marked. Moving to Task #2.

| # | Task | Status | Confirmed |
|---|------|--------|-----------|
| 1 | Create User resource with authentication | done | 2026-01-10 |
| 2 | Add authentication flow handler | in-progress | - |
```

---

## Deferring a Task

```
Claude: Task #3 blocked. Validation requires session config.

        Deferring.

*moves to Deferred section*
*logs in Changes*

| # | Task | Reason | Date |
|---|------|--------|------|
| 3 | Create request validation layer | Awaiting session config | 2026-01-10 |

Moving to Task #4.
```

---

## Recording Plan Changes

```
User: Skip the tests for now. Follow-up PR.

Claude: Deferring Task #4.

*updates Deferred*
*logs change*

| Date | Change | Reason |
|------|--------|--------|
| 2026-01-10 | Deferred Task #4 (tests) | User decision: follow-up PR |
```

---

## Resuming After Context Loss

```
User: Where were we?

Claude: *reads $MEMORY_DIR/blueprint.md*

Resumed.
- Phase: Implementation
- Active: Task #2 (authentication handler)
- Done: 1 | Pending: 2 | Deferred: 2

Continuing Task #2.
```

---

## Completing a Blueprint

```
Claude: All tasks addressed.
        Done: 3 | Deferred: 2

        Mark blueprint complete?

User: yes

Claude: Blueprint complete. Signed off 2026-01-10.
```
