---
name: craft-verdict
description: The committed verdict. Severity, the four fields, and how the loop ends.
---

# Skill: Craft Verdict

> "The argument lives in git, not in a chat log."

## The Standard

- **A verdict is a file**, committed to the branch under review. Not a message.
- **Three severities.** Critical, Warning, Nitpick. Deliberately the same three
  `kernel:craft-review` uses — where kernel is installed, one vocabulary covers both.
- **Four fields per finding.** Missing one means it is not a finding.
- **Only failing oracles and Criticals block.**

## Severity

| Severity | Definition | Blocks? |
|---|---|---|
| Critical | Must fix. Correctness, security, architecture violation. | **Yes** |
| Warning | Should fix. Technical debt, maintainability. | No — recorded as residual risk |
| Nitpick | Could fix. Style, minor preference. | No |

A failing oracle command blocks regardless of severity. Two oracles contradicting each other is a
**stop** — escalate, do not pick one.

## The Four Fields

- **Issue** — what is wrong
- **Risk** — what breaks, concretely, if it ships
- **Expected change** — the specific edit
- **Principle** — the standard violated, cited

The principle citation is what separates a verdict from taste. Cite whatever standard the project
holds — its conventions, a loaded skill, a linter rule. That one exists and is named matters more
than where it came from.

## The Artifact

```
verdicts/
├── 001-adversary-verdict.md
├── 002-adversary-verdict.md
└── approval.md              branch · commit · rationale · residual risks
```

Sequence-numbered, prefixed by role when a panel has more than one judge. Committed, so the whole
argument is readable a year later from `git blame`.

```markdown
## Verdict: REVISE            # REVISE | APPROVE | DEADLOCK
Reviewed: feat/gift-cards @ a1b2c3d4e5

### What's Good
### Critical    — blocks
### Warning     — recorded as residual risk
### Nitpick     — recorded or dropped
### Promote     — judgments recurring often enough to become oracles
```

**`What's Good` is not politeness.** It records verification that came back positive. A format that
can only prosecute makes approval carry no information.

## How The Loop Ends

**By silence.** On approval, write `approval.md` and stop handing off. There is no done state — you
simply do not send another verdict.

Three rules keep it terminating:

1. **Severity floor** — only oracles and Criticals force another round.
2. **Ratchet** — verdict N+1 cites only unresolved items and fix-induced regressions. No new
   Warnings or Nitpicks after round one. A new **Critical** is always admissible.
3. **Approval licence** — an approval with residual risks recorded is a successful review.

On cap exhaustion: **DEADLOCK**. Name the disagreement precisely and escalate. Conceding to end the
loop is worse than deadlocking.

## The Anti-Patterns

| Don't | Do | Why |
|---|---|---|
| Verdict in chat | Verdict in git | The argument must outlive the session |
| "This could be better" | Issue · Risk · Expected change · Principle | Unactionable findings burn a round |
| Everything Critical | Use the floor | If all findings block, none are prioritised |
| New nitpicks in round three | Ratchet | Protects your thoroughness, not the work |
| Approving with nothing recorded | Record residual risks | Silence reads as "nothing was wrong" |
