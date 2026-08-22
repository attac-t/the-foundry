---
name: craft-verdict
description: The committed verdict. Severity, one row per finding, and how the loop ends.
---

# Skill: Craft Verdict

> "What can be said in one word must not take three."

## Severity

| Sev | Means | Blocks |
|-----|-------|--------|
| `C` Critical | Correctness, security, architecture violation | **yes** |
| `W` Warning | Debt, maintainability | no — residual risk |
| `N` Nitpick | Style, preference | no |

A failing oracle blocks regardless. Two oracles disagreeing is a **stop** — escalate, don't pick one.

## A Finding Is A Row

```markdown
| Sev | Where | Issue | Change | Principle |
|-----|-------|-------|--------|-----------|
| C | craft-spec:30 | ":30 forbids self-run gates, :34 shows how | scope it to solo walks | Law 1 |
```

`Where` is `file:line`. Everything else is one clause.

**Risk is not a column.** Severity carries it — a Critical *is* "this breaks." Add one only when
severity fails to convey it: *"passes single-threaded, fails under load."*

**Principle is not optional.** It is the only thing separating a verdict from taste.

## Budget

| Section | Limit |
|---------|-------|
| Findings | one row each |
| What's Good | 3 bullets — only what a refactor would *lose* |
| Promote | one line each |
| Anything else | doesn't exist |

Over ~40 lines is itself a finding. **Candidate oracle:** `wc -l` against a threshold.

## Read The History First

Prior verdicts are input, not archive. Before forming a finding, read `verdicts/`:

- Raised **3 times** → `Promote` candidate, not a fourth finding.
- Approved over **3 times** → no longer residual. Raise the accumulation, not the instance.
- Already settled → don't re-raise unless it worsened.

Slop is invisible in one diff and obvious across forty. A judge that can't see forty can't see slop.

## Deeper

| | |
|---|---|
| [artifact](artifact.md) | the files a review leaves, and the verdict template |
| [ending](ending.md) | SPLIT, the bar and the ratchet, and DEADLOCK's two triggers |

## The Anti-Patterns

| Don't | Do |
|-------|----|
| Verdict in chat | Verdict in git |
| Everything Critical | Use the bar |
| New nitpicks in round three | Ratchet |
| Approve without recording risks | Record them |
| "Recording what held…", "That is the point:", "Worth noting" | Delete. Meta-narration. |
| Restate the table in prose below it | The table said it |
