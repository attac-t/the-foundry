# ADR-002: Every plugin has a skill budget, and the build enforces it

**Status**: Accepted
**Date**: 2026-07-27

## Context

`evolve` runs on a schedule and asks what the plugin should learn from a moving
ecosystem. Left alone, that loop only ever grows: every run finds *something*
plausible, each addition looks individually defensible, and nothing in the process
argues for removal. A year of monthly runs produces a plugin nobody can read.

The cost is not disk. `evaluate.sh` forces Claude to judge every installed skill
yes/no on every prompt, so each skill is a **recurring** context tax on every
session. The 117th skill makes the other 116 slightly less likely to fire.

Exhortation does not hold a line. "Be strict" in a skill body is advice the next run
can rationalise past.

## Decision

Each plugin declares a maximum skill count. `.github/validate.sh` fails when a
plugin exceeds it.

Budgets are set at the current count. Every plugin ships full:

| Plugin             | Budget |
|--------------------|--------|
| `kernel`           | 32     |
| `laravel-ddd`      | 46     |
| `laravel-playbook` | 29     |
| `pest`             | 11     |

Adding a skill therefore requires deleting one, or raising the budget in a commit
that argues for it in the message. Both are deliberate acts a reviewer sees.

**Rejected: trust the merit bar in `evolve`.** A gate a process can talk itself
through is not a gate. This is the same reasoning as
[ADR-001](ADR-001-plugin-version-single-source.md): make the failure structural
rather than remembered.

**Rejected: budget by total line count.** It would push authors toward terse,
cryptic skills, when the real cost is the number of decisions Claude must make per
prompt, not bytes on disk.

**Rejected: a generous budget with headroom.** Headroom is consumed, quietly, and
the cap only starts binding once the plugin is already too big to review.

## Consequences

+ Growth becomes a trade with a visible loser, so the ecosystem's churn cannot
  silently inflate the plugin.
+ A raise is one line in a diff, which is exactly where that argument belongs.
+ `evolve` gets a real default: propose nothing, because there is no free slot.
- Legitimate additions now cost an argument. That is the intent, and it will
  occasionally be annoying.
- The numbers are judgement, not derivation. They are the counts that existed when
  four people could still hold each plugin in their head.
