# Verdict 008 — adversary — APPROVE

Charter: an approval proves its own review
Reviewed: `feat/verdicts-on-disk` @ **7833007**. Round five, ratchet binding. Recorded by the parent.

**007's Critical discharged.** `verdicts.py:107-113` refuses a zero-seat roster, placed after the
in-flight return at `:103-105`. `flat-roster/charter.md:5` keeps the roster backticked and
comma-joined, so `ROLE` cannot match it, `seated()` returns `[]`, and with `approval.md` present the
row lands on the new refusal — asserting exit 1 **and** *"seats no judge"*, not the empty-trail path
`empty-verdicts` already held. `judges.py:125-126` refuses the same charter. The two gates agree.

**007's Promote landed in-round** — seven of eleven rows assert a fragment of the failure line.
**007's Challenge discharged** — the spec no longer asserts what the charter withdraws.

No finding stands. SPLIT considered and declined: `charter.py` is already the single shared parser,
`verdicts.py` has one reason to change, and no fixture needs setup from a concern it does not test.
**Four Criticals across four rounds each named a different failure mode of one deliverable.**

## What's Good

- `verdicts.py:59-62` — `found and name in read(entry)` short-circuits, so `verdicts/judges-are-peers/`
  is skipped before `read()` could `die(USAGE)` on a directory. Hoist `read()` out of that guard and
  the live repo breaks; no fixture would catch it.
- `flat-roster/charter.md:5` — the fixture carries the corpus's *syntax*, not an abstraction of it.
  Remove the backticks and it silently becomes a seated panel, and the row stops gating its path.
- `verdicts.test.sh:32-36` — the reason check is a third failure branch rather than folded into the
  code check, so a row that exits right for the wrong reason reports which fragment it wanted.

## Promote

`panels/flat-roster-in-flight` — flat roster, no `approval.md`, asserting **0**. `charter:25`
requires `verdicts.py:103` to precede `:107`; swap them today and no row turns red.

## Challenge

- `charter:4` linked `verdicts/approval.md` for the **closed** `judges are peers` run. That file is
  at `verdicts/judges-are-peers/approval.md`. Recording this approval converts a broken link into a
  wrong one — it resolves, to a document about something else.
- `charter:62` and `:68` both called a different fixture "the `bulibeef` shape". Two halves, one name.
- Disclosure 1 traced by reading, not executed by the judge: `complete/charter.md:3-6` is isomorphic
  to this charter's `## Panel`; `007-adversary-verdict.md:3` carries the title; `7833007` satisfies
  `COMMIT`. The parent runs it.

## Disposition

Approved. `verdicts/approval.md` recorded verbatim from the judge.

All three challenges closed after issuance and recorded there: the charter link now points at the
archived run, the two fixtures no longer share a name, and the `Promote` shipped as
`panels/flat-roster-in-flight`. Suite 11 → **12**.

**The complete-trail path has now run for real.** It passed against fixtures alone for five rounds;
recording this approval was its first live input, and `bin/verdicts.sh` returns 0 citing one role on
record. That was residual risk 3, closed by the act of closing.
