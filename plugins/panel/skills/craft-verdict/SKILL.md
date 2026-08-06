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

## Before You Judge — read the history

**Prior verdicts are input, not archive.** Read `verdicts/` before forming a finding.

Three things to look for:

- **A finding you are about to raise that has been raised before.** Count it. Three occurrences is a
  promotion candidate — put it in `### Promote` rather than raising it a fourth time.
- **A residual risk that keeps reappearing.** A risk approved over three times has stopped being
  residual; it is *accumulating*. Raise the accumulation, not the instance.
- **A finding already approved over.** Do not re-raise it unless it got worse. Re-raising settled
  findings is how a judge becomes noise, and noise is how gates get overridden.

Without this every run is amnesiac. **Slop is invisible in any single diff and obvious across
forty** — a judge that cannot see the forty cannot see slop at all, however good its taste.

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
├── approval.md              branch · commit · rationale · residual risks
└── cold-read-log.md         gate-2 timings, one row per run — the slop metric
```

`cold-read-log.md` is a series, not a document. `/verdict` appends `panel:newcomer`'s four timings
to it. A single reading is noise; the column is the only instrument that sees gradual decay, because
**every individual change looked fine at the time.**

Sequence-numbered, prefixed by role when a panel has more than one judge. Committed, so the whole
argument is readable a year later from `git blame`.

```markdown
## Verdict: REVISE            # REVISE | APPROVE | DEADLOCK
Reviewed: feat/gift-cards @ a1b2c3d4e5     # stamped by /verdict, not the judge

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

## DEADLOCK has two triggers

**Exhausted** — the iteration cap ran out and disagreement stands.
**Out of category** — the disagreement needs a fact the team does not hold.

The discriminator is not confidence. It is *what kind of fact settles the argument*:

| Settled by | Then |
|------------|------|
| Code, spec, oracle output, a past verdict | **The team decides.** Do not escalate. |
| Business intent, priority, risk appetite, what the customer meant | **Escalate.** |

Conflating these is why teams either escalate everything or bluff. Name which trigger fired.

Deadlocking out of category early is correct and cheap. Burning six rounds to arrive there is not.
Conceding to end the loop is worse than either.

## The Anti-Patterns

| Don't | Do | Why |
|---|---|---|
| Verdict in chat | Verdict in git | The argument must outlive the session |
| "This could be better" | Issue · Risk · Expected change · Principle | Unactionable findings burn a round |
| Everything Critical | Use the floor | If all findings block, none are prioritised |
| New nitpicks in round three | Ratchet | Protects your thoroughness, not the work |
| Approving with nothing recorded | Record residual risks | Silence reads as "nothing was wrong" |
