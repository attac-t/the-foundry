# Approval — judges are peers

**Branch** `feat/judges-are-peers` · **Approved at** `8f67d1a` · **Panel** `panel:author` (author) ·
`panel:adversary` (gate 1)

`1d9708e` → `1f11ad6` → `8f67d1a` → `<fixes>`

| Round | Gate 1 |
|-------|--------|
| 001 | REVISE — 4 C. Judged the **sub-team model**, which this charter rejects and replaces |
| 002 | REVISE — 4 C, 5 W, 1 N. Unanchored working tree; could be performed, could not close |
| 003 | **APPROVE** — 4 W, ratchet binding |

## Rationale

Every Critical from 002 discharged against a SHA, verifiable in the artifact rather than the brief.
The suite is a committed oracle that accounts for itself. `judges.sh` failed closed under adversarial
probing — bulleted, bolded, tabulated and comma-joined rosters all reach 1 or 2, never a silent 0.
The charter records what it weakened rather than what it wished.

**The judge paid for itself twice.** Two of 002's Criticals were exit-0-when-it-should-fail bugs
invisible to the seven assertions then existing: a plugin pin falling through to a search and
certifying *another plugin's* agent, and a gate assignment overwriting the judges named first. The
third killed the fixture set — seven copies of one shape, so a total parse failure scored 7/7.

## Residual risks

Closed after issuance, in the follow-up commit — recorded here rather than silently folded into the
approved SHA:

1. ~~`gates.yml` runs neither new gate~~ — both added as steps. 003's `Promote`, landed.
2. ~~`bin/repeats.sh:22` and `gates.yml:32` keep the tracked-only `git ls-files`~~ — both now
   `-co --exclude-standard`.
3. ~~`README:54` claims three gates above a five-row table~~ — corrected.
4. ~~`charter:135-136` overstates which fixtures are rename-proof~~ — narrowed to the three that are.

Standing:

5. **`judge-can-write.md` names `kernel:architect` deliberately** — something must prove the pin
   resolves against the real tree. If kernel renames that agent the fixture keeps asserting `1`
   through the *unresolved* branch rather than Law 4, and degrades without saying so.
6. **`pest:critic` is shipped and unexercised.** It judges Pest suites; this repo has none. Its
   eligibility is certified, its judgement is not.
7. **Every gate result is one machine, once.** GitHub Actions is billing-locked on this account and
   cannot obtain a runner. The two new steps in `gates.yml` have never executed.
8. **The flat-roster diagnostic at `judges.sh:118-130` has no fixture** — the shape the charter calls
   the only one in existence is unexercised. Raised by the judge outside the ratchet.
9. **`judges.sh` certifies a file, not a seatable agent type.** Whether the harness can seat
   `pest:critic` is declared ungateable in the charter and remains unverified.

## Closed

**Chris Attard — 2026-08-07**, on the charter. Both the goal gate and the judged gate approving was
the precondition; this is the approval.

`feat/judges-are-peers` descends from `feat/panel-convening`, so a pull request from it must target
that branch rather than `main` — otherwise it carries PR #54's commits, which the charter scoped out.

Next, and larger than anything closed here: **verdicts that never reach disk.** `bulibeef` ran four
rounds across two gates and committed none of them, so Law 5 and the memory mechanism never operated
on the only production run panel has had. Observed in both repositories. Its own charter.
