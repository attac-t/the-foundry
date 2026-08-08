# Verdict 006 — adversary — REVISE

Charter: an approval proves its own review
Reviewed: `feat/verdicts-on-disk` @ **fb0a979**. Round three, ratchet binding. Recorded by the parent.

005's Critical and Warning both discharged — verified at `craft-verdict:60-73`, `adversary.md:91-93`,
`verdicts.py:49-61`, `:64-68`. Both challenges landed.

| Sev | Where | Issue | Change | Principle |
|-----|-------|-------|--------|-----------|
| C | `charter:63` | the one real-corpus run is unchecked and no verdict carries it — 004, 005 and the brief mention `bulibeef` but no exit code was handed over; "hand-run, uncommitted" is a model reporting a command outcome | parent runs it and hands the exit code **and the `FAIL —` line**; the code alone cannot tell `refuse_empty` from `refuse_foreign`, and `charter:57` claims the former | `adversary.md:34-36`; `craft-oracle` — an unrun oracle is not a passing one |
| W | `panel/README:182-183`, `verdicts.py:7-9` | both still say archiving is what scopes the trail, which `verdicts.py:52-54` now calls housekeeping; one file contradicts itself and the text filter reads as redundant | make both say the join is textual | unresolved remainder of 005 W2; fix-induced by `8ca7e4f` |

## What's Good

- `panels/stale-trail` + `verdicts.test.sh:44` — delete `and name in read(entry)` and this row goes
  red. Before `fb0a979` the textual join had no input that failed without it.
- `judges.test.sh:26-31` — `absent()` inverts the guard rather than exempting a class.
- `.gitignore:31-33` — the rule carries why it exists, so a future tidy-up cannot read it as boilerplate.

## Promote

A `panels/flat-roster` fixture reproducing `bulibeef`'s actual shape, asserting the exact code —
third time an unexercised path has been named, and it puts the real corpus's structure somewhere an
external path cannot move.

## Challenge

- **The shipped fix is not what this session is running.** The `craft-verdict` in the judge's context
  is plugin cache `0.6.2`; the repo is at `0.9.1`. Every review this session ran against the
  *installed* skills, not the working tree.
- **`recorded()` joins by substring.** A follow-on charter whose title contains this one's would be
  discharged by this run's verdicts. Ratchet-barred; residual risk.
- `__pycache__/charter.cpython-314.pyc` regenerates on disk, gitignored.

## Disposition

**Critical fixed by withdrawing the claim it protected.** Running `bulibeef` with its output shown
returned **0**, not 1 — that repository has since opened `charter-2.md` and deleted `verdicts/`
entirely. The gate did not change; the corpus moved. The charter's external assertion is withdrawn
and its `Promote` taken in the same round: `panels/flat-roster` carries the shape permanently.

**A corpus you do not own stops being evidence without telling you.** Asking for the failure line
rather than the exit code is the only reason this surfaced.

Warning fixed in both files. Bytecode now suppressed at the wrapper rather than ignored.

**And the demand for real output found a second thing.** `bin/repeats.sh` skipped unreadable
arguments silently and reported the *argument* count — three paths, one file read, "across 3 files".
Under Windows fork exhaustion it printed PASS while its subprocesses died. Every `PASS — N files`
cited this session was a claim about arguments. Fixed in `fcd3b55`.

**Not closed.** Round four judges these fixes.
