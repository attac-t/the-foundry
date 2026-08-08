# Charter: an approval proves its own review

Follows `judges are peers`, approved and closed 2026-08-07 — see
[its approval](verdicts/judges-are-peers/approval.md), whose closing paragraph names this defect as
the larger one. `verdicts/approval.md` is *this* run's, and pointing at it here would resolve to a
document about something else.

## Goal

**An `approval.md` that cannot show the verdicts it claims is a review that did not happen.**

`craft-verdict` specifies the artifact tree and `adversary.md:26-27` assigns the recording to the
parent. Both are instructions to a model, and the model is also the thing that would have to obey
them — `ground-mechanism`: *if a model's output is the enforcement, there is no enforcement.*

It did not hold. `bulibeef`'s completed run — the only time panel has met production work — records
four rounds across two gates in `approval.md` and committed **zero** of the eight judgements. Law 5
never operated. `craft-verdict`'s *Read The History First*, the promotion rule, the
raised-three-times counter: all inert, on the one run that mattered.

Stated so it could be false:

- `bin/verdicts.sh` exits non-zero when `approval.md` exists and any judge seated on a gate has no
  `NNN-<name>-verdict.md` beside it.
- It exits non-zero when `approval.md` cites no commit — verdict 002 established that an approval
  without a SHA cannot close, because the next judge cannot reconstruct what this one read.
- It exits **zero** on a run in progress. A charter mid-flight has no approval and owes no trail.
- It refuses a charter that seats **no** judge while claiming an approval — nobody owes a verdict,
  so nothing can be missing, so the trail proves nothing. `judges.sh` refuses the same charter, and
  two gates disagreeing about one roster is what sharing a parser exists to prevent.
- The pre-moments shape `bulibeef` had fails, **as a fixture** — see `## Done when`. The original
  claim named that repository directly and is withdrawn.

**It reuses `judges.sh`'s `## Panel` parser.** Who is seated on which gate is exactly who owes a
verdict, so the moments format pays a second dividend and the two gates cannot disagree about the
roster.

**Why a gate and not a better instruction.** The instruction exists, is unambiguous, and lost. Adding
a second one is the mechanism that already failed, applied harder.

## Prior art

**Gilb & Graham (1993)** make the defect log a required artifact of the inspection, not a by-product
of it. Panel has the log in `craft-verdict` and no step that requires it.

One observation worth designing around: in `bulibeef`, `cold-read-log.md` **survived** while every
numbered verdict did not. The artifact you append a row to persisted; the artifact needing a fresh
file each time did not. Cheapness of the write predicted survival better than any rule did.

## Done when

Assertions against fixture panel directories, each asserting an exact exit code **and, where the
reason matters, a fragment of the failure line**. An exit code alone cannot tell one refusal from
another, and three consecutive verdicts turned on exactly that.

- [x] `bash plugins/panel/tests/verdicts.test.sh` → **0**

Behaviours it must carry:

| it | exit |
|----|------|
| passes a complete trail — every seated judge has a verdict, approval cites a SHA | 0 |
| passes a run in progress — no `approval.md` yet, whatever the roster | 0 |
| refuses an approval above a `## Panel` that seats nobody | 1 |
| refuses an approval naming another charter, or a trail that does | 1 |
| fails an approval with an empty `verdicts/` | 1 |
| fails when one gate's judge is missing a verdict and another has one | 1 |
| fails an approval that cites no commit | 1 |
| refuses a panel directory with no charter | 2 |

- [x] `bash plugins/panel/bin/verdicts.sh` → **0** against this repo's own panel directory
- [x] the `bulibeef` shape fails — as `panels/flat-roster`, **not** as a path into another repository

**The external-corpus assertion was withdrawn, and why matters more than the fix.** The charter said
*"run against `bulibeef`'s panel directory it fails"*. It did, once. By round three that repository
had opened `charter-2.md` and removed `verdicts/` entirely, so the same command now returns **0** —
correctly, for a run in flight. The gate did not change; the evidence moved.

A judge asking for the failure *line* rather than the exit code is what surfaced it. `0` and `1`
both looked like the story until someone wanted to know which refusal fired. **A corpus you do not
own stops being evidence without telling you**, so its shape is now a fixture: flat pre-moments
roster, an approval claiming four rounds, `cold-read-log.md` surviving because appending a row is
cheaper than creating a file, and not one verdict.

Standing — must still exit zero at the end:

- [x] `bash bin/frontmatter.sh`
- [x] `bash bin/versions.sh`
- [x] `bash bin/repeats.sh $(git ls-files -co --exclude-standard 'plugins/panel/*.md' 'plugins/pest/*.md')`
- [x] `bash plugins/panel/tests/judges.test.sh`
- [x] `bash plugins/panel/bin/judges.sh`
- [x] Judged: `panel:adversary` approves, with residual risks recorded — verdict 008 @ `7833007`

## Stated, ungated

**A gate cannot make a verdict truthful, only present.** A file with the right name and empty
findings passes. That is the same limit `craft-oracle`'s Coverage Rule names, and it is why this
gate is worth less than it looks — it removes the silent-zero case, not the lazy-verdict case.

**`bulibeef`'s eight missing verdicts are unrecoverable.** They were never written. The gate stops
the next run losing its trail; it cannot restore that one.

## Gates weakened

**GitHub Actions is billing-locked. No workflow can obtain a runner.** Every result is self-run, one
machine, once — including the two steps `judges are peers` added to `gates.yml`, which have still
never executed.

## Out of scope

- **Making `/verdict` write or commit automatically.** That is the parent's behaviour, and a gate
  that catches the omission afterwards is the deterministic half. Instruction changes are the half
  that already failed; changing them again without evidence is guessing.
- **`cold-read-log.md`.** Gate 2's series survived; it is not the defect.
- **Retrofitting `bulibeef`.** Read-only here.
- **The ratchet versus Fagan's full re-inspection on non-trivial rework** — a real conflict with the
  canon, still unowned, still its own charter.
- **A verdict's contents.** Present, not good.
- PR #54, and the `judges are peers` branch this one descends from.

## Panel

author:  `panel:author`
gate 1:  `panel:adversary`

## Approved

Chris Attard — 2026-08-07
