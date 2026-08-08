# Approval — an approval proves its own review

**Branch** `feat/verdicts-on-disk` · **Approved at** `7833007` · **Panel** `panel:author` (author) ·
`panel:adversary` (gate 1)

| Round | Gate 1 |
|-------|--------|
| 004 | REVISE — 1 C, 5 W. The trail was never joined to the run it proved |
| 005 | REVISE — 1 C, 1 W. Fix-induced: the gate demanded what no shipped instruction asked for |
| 006 | REVISE — 1 C, 1 W. The one real-corpus claim had never been run with its output shown |
| 007 | REVISE — 1 C. A `## Panel` parsing to zero seats passed, while `judges.sh` refused it |
| 008 | **APPROVE** — ratchet binding, no finding standing |

## Rationale

`bin/verdicts.sh` refuses an `approval.md` that cannot show its verdicts, and every refusal has a
fixture that exits for the reason claimed rather than merely with the code claimed. Twelve
assertions, seven of them asserting the failure line — the discrimination three consecutive
Criticals turned on.

**The charter records what it withdrew and why.** The external-corpus assertion was true once and
stopped being true without the gate changing. That paragraph is worth more than the assertion it
replaced: a corpus you do not own stops being evidence without telling you.

**Both gates now answer the roster identically.** `judges.py:125-126` and `verdicts.py:107-113`
refuse the same charter, which is the whole return on sharing `charter.py`. Before `7833007` they
disagreed — `verdicts.sh` 0 and `judges.sh` 1 on the same input.

## Residual risks

1. **`recorded()` joins by substring** — `verdicts.py:62`. A follow-on charter whose title contains
   this one's is discharged by this run's verdicts. Raised in 006 and 007; ratchet-barred both times.
2. **Round counts are ungated.** One verdict file per role discharges an approval claiming any
   number of rounds. The unclosed half of 004's C1.
3. **This approval is the first real input to the complete-trail path.** Until now it was exercised
   by `panels/complete` alone; `bin/verdicts.sh` passed against this repo only because no
   `approval.md` existed.
4. **A subdirectory inside `verdicts/` has no fixture.** This repo has `verdicts/judges-are-peers/`;
   `verdicts.py:59-62` handles it by short-circuit, uncovered.
5. ~~The branch ordering at `verdicts.py:103` before `:107` is unexercised~~ — closed after issuance:
   `panels/flat-roster-in-flight` asserts it, from verdict 008's `Promote`.
6. ~~`charter:4` links the wrong `approval.md`~~ — closed after issuance; it now points at
   `verdicts/judges-are-peers/approval.md`.
7. **`verdicts.py:26` requires a lowercase role in the filename**, while `roster()` does not enforce
   what `judges.py:16` does. A seat named `panel:Adversary` could never be discharged. `judges.sh`
   refuses it independently, so both gates would have to be bypassed.
8. **A gate makes a verdict present, never truthful.** A correctly-named file with empty findings
   passes.
9. **Every gate result is one machine, once.** GitHub Actions is billing-locked; the five panel steps
   in `gates.yml` have never executed.
10. **The judge's skills were plugin cache `0.6.2`, not the working tree at `0.9.3`**, across all
    five rounds. Every citation was read from the working tree by absolute path.

## Closed

**Chris Attard — 2026-08-07**, on the charter.

Law 5 now has a mechanism instead of an instruction. `bulibeef`'s eight judgements remain
unrecoverable — they were never written.
