---
name: evolve
description: Scheduled self-improvement. Keep the plugin current, cut what no longer earns its place.
---

# Skill: Evolve

> "The default answer is no. Deletion is a result."

## Where This Runs

**In a plugin repository** — this one, or any marketplace built the same way. It
maintains the skills themselves.

The counterpart is [`retrospect`](../retrospect/SKILL.md), which runs in the project
you *use* the plugins on. Evolve keeps the tools sharp; retrospect notices what your
work has been teaching you.

## When

On a schedule — monthly is enough. See [scheduling.md](scheduling.md).

Also by hand after a major platform release.

## The Problem This Solves

A plugin encodes the ecosystem as it was on the day it was written. Models change,
tool APIs move, patterns that were sharp become folklore. Nothing in the repo
notices.

## The Problem This Creates

A recurring "what should we add?" loop only grows. Every run finds *something*
plausible. Each addition looks defensible alone. A year later nobody can read the
thing.

So the budget is a hard wall, not a guideline: **every plugin ships at its cap**
([ADR-002](../../../../docs/adr/ADR-002-skill-budgets.md)). There is no free slot.
An addition must name the skill it replaces, and `validate.sh` fails if it doesn't.

## The Team

Three roles, because one agent asked to "improve things" always finds improvements.
Give each a separate lens and let them disagree.

| Role            | Lens                                    | Owns                    |
|-----------------|-----------------------------------------|-------------------------|
| **Scout**       | What changed out there since we wrote this? | Findings only. No edits. |
| **Prosecutor**  | What in here no longer earns its place?  | Deletion proposals.     |
| **Gatekeeper**  | Does any of this survive the bar?        | The verdict.            |

Scout and Prosecutor run in parallel and never see each other's output. The
Gatekeeper reads both and decides. Brief each with: *"Flag anything in this brief
that seems wrong."*

## The Bar

The Gatekeeper admits a change only when **every** answer is yes.

| Test           | Question                                                      |
|----------------|---------------------------------------------------------------|
| **Behaviour**  | Does this change what Claude *does*, not what it knows?       |
| **Durable**    | Will this still be true in a year?                            |
| **Unowned**    | Name the closest existing skill. Does it genuinely miss this? |
| **Load-bearing** | Would a competent engineer get this wrong without it?       |
| **Funded**     | Which skill are you deleting to make room?                    |

A new model name, a version bump, a renamed API — these are facts. Facts belong in
the skill that already covers the area, or nowhere. They are not new skills.

## The Durability Filter

Ignore anything younger than six months. A pattern that has not survived two
quarters is a trend, and trends are what bloat looks like on the way in.

Exception: a **breaking** platform change. Those are corrections, not additions, and
they cost no budget.

## The Protocol

1. **Scout** — read the current official docs for the platform and each stack the
   plugins target. Report only what *changed* and what breaks as a result.
2. **Prosecutor** — hunt fat, independently:
   - Skills that restate a `ground-*` philosophy in different words
   - `decide-*` skills that state the decision three times over
   - Advice the framework's own docs now give better
   - Anything hedged enough that it takes no position
3. **Gatekeeper** — apply the bar. Reject by default.
4. **Report** — the shape below, then stop. Do not edit.
5. **Human decides.** Open a PR per accepted change, one change each.

## The Output

```
Scouted:   [N] ecosystem changes, [M] survive the durability filter
Prosecuted: [N] deletion candidates
Verdict:   [N] corrections · [N] deletions · [N] additions (each naming its trade)
Budget:    kernel 32/32 · laravel-ddd 46/46 · playbook 29/29 · pest 11/11
```

`0 corrections · 0 deletions · 0 additions` is a good run. Say it plainly and stop.

## The Anti-Patterns

- **Adding because the run happened.** A schedule is not a quota.
- **Chasing a release note.** New API ≠ new skill.
- **Deleting nothing, ever.** If the Prosecutor never wins, it isn't trying.
- **Editing during the run.** This skill reports. Humans merge.
- **Raising the budget quietly.** Raise it in a commit that argues for it.
