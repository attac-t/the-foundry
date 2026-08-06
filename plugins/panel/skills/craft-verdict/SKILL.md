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

## The Artifact

```
verdicts/
├── NNN-<role>-verdict.md
├── approval.md          branch · commit · rationale · residual risks
└── cold-read-log.md     gate-2 timings, one row per run — the slop metric
```

```markdown
## Verdict: REVISE        # REVISE | APPROVE | SPLIT | DEADLOCK
Reviewed: <branch> @ <sha>    # stamped by /verdict, not the judge

| Sev | Where | Issue | Change | Principle |
### What's Good
### Promote
```

## How It Ends

**By silence.** On approval write `approval.md` and stop handing off.

**SPLIT** — the work is sound; the *boundary* is wrong. Not fixable this round. Return to the
charter. Mid-loop decomposition has tells the charter gate cannot see, because they surface only in
code:

| Tell | Reading |
|------|---------|
| the same shape written a third time | it wants to be one thing, elsewhere |
| one file, two unrelated reasons to change | two charters sharing a filename |
| a test needing setup from a concern it doesn't test | the boundary already leaks |

**Any of these outranks the finding you were about to write.** Three Warnings about symptoms of one
mis-sized charter is three wasted rounds and a missed call.

- **Floor** — only oracles and Criticals force a round.
- **Ratchet** — verdict N+1 cites only unresolved items and fix-induced regressions. No new W or N
  after round one. A new **C** is always admissible.
- **Licence** — an approval with residual risks recorded is a successful review.

**DEADLOCK has two triggers.** *Exhausted* — rounds ran out. *Out of category* — the argument needs
a fact the team doesn't hold. The discriminator is not confidence but what settles it:

| Settled by | Then |
|------------|------|
| Code, spec, oracle, past verdict | team decides — escalating is waste |
| Business intent, priority, risk appetite | escalate |

Name which fired. Deadlocking out of category early is cheap; burning six rounds to get there isn't.

## The Anti-Patterns

| Don't | Do |
|-------|----|
| Verdict in chat | Verdict in git |
| "This could be better" | Sev · Where · Issue · Change · Principle |
| Everything Critical | Use the floor |
| New nitpicks in round three | Ratchet |
| Approve silently | Record residual risks |
| "Recording what held…", "That is the point:", "Worth noting" | Delete. Meta-narration. |
| Restate the table in prose below it | The table said it |
