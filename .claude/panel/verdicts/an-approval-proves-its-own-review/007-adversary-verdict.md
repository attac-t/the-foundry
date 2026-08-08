# Verdict 007 — adversary — REVISE

Charter: an approval proves its own review
Reviewed: `feat/verdicts-on-disk` @ **9dc4d5e**. Round four, ratchet binding. Recorded by the parent.

006's Warning discharged — `verdicts.py:7-10`, `:52-55`, `panel/README:184-187`. 006's Critical
discharged by withdrawal, recorded with its reason at `charter:65-74`. Bytecode suppressed at both
wrappers; no `__pycache__` on disk.

| Sev | Where | Issue | Change | Principle |
|-----|-------|-------|--------|-----------|
| C | `verdicts.py:100` | a `## Panel` parsing to **zero** seats is never refused — `missing` iterates an empty list, so an approval claiming four rounds passes on one verdict file. `judges.py:125-126` refuses that same charter, so the two gates disagree about the roster precisely where `charter:28-30` says they cannot. `panels/flat-roster` does not cover it: the backticked list cannot match `ROLE`, so the row exits 1 at `refuse_empty` — the path `empty-verdicts` already gates. Add one verdict and the fixture flips to **0** | `die(FAILED)` on an empty roster after the in-flight return; give `flat-roster` a verdict so the row gates the roster path | `charter:8`; `craft-oracle`, *A Green Gate Can Be Empty* — the inputs dodge the failure mode |

## What's Good

- `repeats.sh:44-55` — the refusal carries the fork-exhaustion story that produced it, so a later
  tidy-up cannot read the loop as a redundant existence check.
- `charter:65-74` — the withdrawn assertion is kept and explained rather than deleted. Erasing it
  would lose why `flat-roster` exists.
- `verdicts.sh:11-13` — `PYTHONDONTWRITEBYTECODE=1` is tied in comment to the committed `.pyc`;
  without that the `env` wrapper reads as ceremony and gets dropped.

## Promote

`it()` takes an expected `FAIL —` fragment and greps for it. A row asserting only the code cannot
tell `refuse_empty` from `refuse_missing`. **Third time this judgement fires** — 004 W3, 006 C, and
the Critical above. Demanding the failure *line* is what surfaced all three.

## Challenge

- `charter:26` still asserted a claim the charter retracts at `:65-68`, and `charter:46` contradicted
  `:63` the same way. A reader who stops at the spec reads a false spec.
- The brief's "carries the shape permanently" overstated the fixture: it carried the empty trail,
  which `empty-verdicts` already carried. The flat roster — the half that named it — went untested.
- Disclosure 2 confirmed, ratchet-barred: `recorded()` joins by `in`, so a follow-on charter whose
  title contains this one's would be discharged. Residual risk.
- Disclosure 3 does not taint the verdict: the judge's skills are cache `0.6.2`, but every citation
  was read from the working tree by absolute path.

## Disposition

**Critical fixed and demonstrated.** Before: `verdicts.sh` returned 0 and `judges.sh` returned 1 on
the same `flat-roster` charter. `verdicts.py` now refuses an empty roster after the in-flight return,
`flat-roster` carries a verdict, and its row gates *"seats no judge"* rather than the empty-trail
path it shared with `empty-verdicts`.

**The `Promote` landed in the round it was raised.** `it()` now takes a fragment of the expected
failure line; seven of eleven rows assert the reason as well as the code. A gate that says only
`1` cannot tell you which refusal fired, and three verdicts running turned on that.

Both charter contradictions corrected — the spec no longer asserts what the charter withdraws.

**Not closed.** Round five judges these fixes.
