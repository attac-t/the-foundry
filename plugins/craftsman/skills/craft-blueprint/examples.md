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
| 1 | Create User model with authentication traits | in-progress | - |
| 2 | Add LoginController with validation | pending | - |
| 3 | Create authentication middleware | pending | - |
| 4 | Write Pest tests for auth flow | pending | - |
| 5 | Update routes and config | pending | - |

Starting Task #1.
```

---

## Requesting Confirmation

```
Claude: Task #1 complete.
        - Created app/Models/User.php
        - Added HasApiTokens trait
        - Configured $fillable and $hidden

        Confirm to mark done?

User: confirmed

Claude: Marked. Moving to Task #2.

| # | Task | Status | Confirmed |
|---|------|--------|-----------|
| 1 | Create User model with authentication traits | done | 2026-01-10 |
| 2 | Add LoginController with validation | in-progress | - |
```

---

## Deferring a Task

```
Claude: Task #3 blocked. Middleware requires session config.

        Deferring.

*moves to Deferred section*
*logs in Changes*

| # | Task | Reason | Date |
|---|------|--------|------|
| 3 | Create authentication middleware | Awaiting session config | 2026-01-10 |

Moving to Task #4.
```

---

## Recording Plan Changes

```
User: Skip the Pest tests for now. Follow-up PR.

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
- Active: Task #2 (LoginController)
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
