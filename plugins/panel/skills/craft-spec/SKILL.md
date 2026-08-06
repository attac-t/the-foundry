---
name: craft-spec
description: From business need to code, in order. Eleven steps, two gates.
---

# Skill: Craft Spec

> "Specification work cannot be removed. Only moved."

Moving it up front, into artifacts that outlive the session, is cheaper than discovering it in
production. That is the whole claim.

An opinionated composition of Evans' aggregates, Meyer's contracts, and Cockburn's ports —
sequenced. None of those three says what order to do them in. **The order is the contribution.**

## The Boundary

**This governs code that *decides*. It does not govern code that *depicts*.**

It applies wherever there is a decision spine — state that must not be corrupted, guarded by
transitions. That includes transactional domain logic **and state-machine UI**: a wizard is a state
machine wearing CSS.

It **idles** on projections — reports, transforms, rendering — where verification is golden examples
plus algebraic properties. It can host those; it cannot derive them. Read the boundary before you
start, not at step 9.

## Prerequisite

**Inside a convened panel, steps 4 and 10 may not be run by whoever did the work. No exception.**
Self-assessment of this kind runs near 29% accuracy, applied at the moment of maximum authorial
investment. `panel:adversary` judges gate 1; `panel:newcomer` judges gate 2.

**Walking this alone is a different thing, and legitimate** — the eleven steps are worth following
without a panel. There the gates degrade to self-checks: gate 1 by writing client code from three
callers, gate 2 cold after a deliberate gap. Say in writing that you did. A weak gate that declares
itself is honest.

But a solo walk is **not a panel run**, and must not be recorded as one. Law 1 admits no degradation
inside a panel; that is the whole of what a panel is.

## The Walk

The numbering is the **order the artifacts depend on each other**, not an execution sequence.
Discovery runs upward in practice, and looping is expected — see *Re-entry*.

| # | Step | Act | Done when |
|---|------|-----|-----------|
| 0 | Domain knowledge | Indicative facts that hold whether or not you build anything | Every term used in a need is grounded in one |
| 1 | Needs | What must become true, stated so it could be false | Every term is an environment phenomenon, and *why* bottoms out at money, risk, time, or obligation |
| 2 | Invariants | Negate each need; derive the obstacles | Each has a consistency boundary, and transactional-vs-eventual is decided |
| 3 | Ports | Driving and driven | Two to four. Fifteen means adapters wearing port costumes |
| 4 | **Gate 1** | Signature draft, empty bodies | A non-author judge approves the shape |
| 5 | Contracts | Classify each: precondition, postcondition, class invariant, constraint | Every invariant has a terminus |
| 6 | Assertions | Derive from the contracts and the input partition | Every contract has at least one test |
| 7 | Primitives | Make illegal states unconstructable | Assertion count **dropped** |
| 8 | Adapters | Wire the ports. Hooks at ports only | A different client could consume this unchanged |
| 9 | Bodies | Implement | Every gate exits 0 |
| 10 | **Gate 2** | Cold read | Someone who wasn't here can rebuild the theory |

**Blame assignment is why step 5 has four termini, not one.** A precondition violation is the
caller's bug, a postcondition the supplier's, an invariant the class's. Collapse them and a failing
contract is merely red instead of diagnostic. The fourth — a **constraint** enforced below the code,
a unique index or a serialisable transaction — is where concurrency properties live, and no draft
can show it.

## Drafting — how step 4 comes to exist

Every element derives from an earlier step. Nothing is invented here.

```
one entry point per driving-port intent          step 3   (not per HTTP route)
the receiver is the aggregate                    step 2
each chain link is one obstacle                  step 2
the return type is the need                      step 1
nothing else                                     — no parent, no place in the draft
```

Types in the draft are **provisional**. Step 7 may replace them, and a signature change re-opens
gate 1. That is expected — the draft is cheap precisely so it can be redrawn.

## Gate 1 — the signature draft

Empty bodies. Judge before implementation exists, because an empty draft is free to discard and
filled-in code is not.

**Do not read your own draft — write client code against it, from three different callers.** Reading
your own naming always feels obvious.

Two things the draft must make visible, since both vanish once bodies exist: whether the chain's
order is a real dependency or an invented one, and whether a step throws or returns a flag.

## Gate 2 — the cold read

A program is a **theory** held by the people who built it; the text is its shadow. A newcomer does
not read the theory, they rebuild it. Four timed tests, run by someone who wasn't here:

```
locate      Given a need in business words, find the code.
            Failure means the business term is not an identifier.

understand  From the draft and contracts only — no bodies — say what this does
            and one thing that would break it.

predict     Shown only the draft: what happens when a guard fails?
            If they cannot say whether it throws, the chain hides its failure mode.

change      Make a small change and know whether it broke something.
```

Record the numbers. **A regression in time-to-understand is a finding**, the same as a failing test.

> **If this step requires writing new documentation, the walk leaked.** Steps 0–5 already produced
> the theory. Step 10 mostly publishes what exists.

## Re-entry

The walk is a **reconciliation structure, not a generation procedure.** Discovery runs upward in
practice — a webhook found at step 3 will rephrase an invariant at step 2 and surface a need at
step 1 that nobody stated.

```
a new port          → re-derive invariants (2), redraw the draft (4)
a signature change  → gate 1 re-runs
a new Critical      → always admissible, at any round
a new Warning       → not after round one (see panel:craft-verdict)
```

Looping is expected. An unrecorded loop is not.

## The Anti-Patterns

| Don't | Do | Why |
|-------|----|-----|
| Start writing bodies | Draft signatures first | Empty drafts are free to throw away |
| Judge your own draft | Three callers, or a second agent | 29% accuracy, at peak investment |
| One `ensure` per test | One contract, ≥1 test | Boundary values are one dataset, not three tests |
| A primitive that adds assertions | Delete assertions | If count rises, it is a wrapper |
| Test a rule at three altitudes | Lowest one still about behaviour | Triplication reads as thoroughness |
| Enumerate ports as technologies | Enumerate intents | HTTP is an adapter, not a port |
| Walk it on a projection | Golden examples plus properties | The chain idles; it does not fail loudly |
