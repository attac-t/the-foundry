# Verdict 003 — adversary — APPROVE

Reviewed: `feat/judges-are-peers` @ **8f67d1a**. Round two. Ratchet binding. Recorded by the parent.

**002's four Criticals are discharged, verified against the artifact rather than the brief.**
C1 — `judges.sh:70-77` returns `None` on a missed pin, no `rglob` fallthrough. C2 — `:109`
`setdefault(...).extend`. C3 — 15 assertions; `fenced-decoy.md`, `two-panel-sections.md` and the
following-`##` construct all present. C4 — `charter:196-205`. W1 `:33-37,48-52`; W2 the committed
suite with a zero-assertion guard `:67-70`; W4 `charter:161-165`; W5 `charter:12-18`; N1 `:48-52`.

| Sev | Where | Issue | Change | Principle |
|-----|-------|-------|--------|-----------|
| W | `charter:135-136` | "Negative cases resolve against `tests/agents/`" is false — `judge-can-write.md:6` and `fenced-decoy.md:14` still name `kernel:architect`; both assert `1`, which a kernel rename preserves via the *unresolved* branch, not Law 4 | repoint at `writer` under `PANEL_AGENT_PATH`, or narrow the sentence | 002 W3 unresolved; `craft-oracle`, *A Green Gate Can Be Empty* |
| W | `.github/workflows/gates.yml` | the PR gate definition runs three steps; `judges.test.sh` and `judges.sh` — this charter's deliverable and 002's `Promote`, claimed discharged at `charter:177` — are in neither | add both as steps | `craft-oracle`, *A Green Gate Can Be Empty* |
| W | `bin/repeats.sh:22`, `gates.yml:32` | the disclosed tracked-only `git ls-files` is fixed in `README` and `charter` and left in both other copies; `:22` is the live one | fix `:22` to `-co --exclude-standard`; sync `:32` | `craft-oracle`, re-specifying a raw invocation duplicates a definition that will drift |
| W | `README.md:54` | "Three gates run on every pull request" sits above a five-row table and fifteen lines above "they do not run in CI" — wrong twice | drop the count, or "five gates, run locally" | fix-induced regression |

## What's Good

- `judges.sh` fails closed under every probe constructed — bulleted, bolded, tabulated and
  comma-joined rosters all reach exit 1 or 2, never a silent 0. Nothing tried seats a writer green.
- `:138-154` separates `unresolved` from `law4`, and `:167-169` invokes the law only when it broke.
- `charter:161-165` declares `pest:critic` shipped-but-unexercised instead of seating it for the
  coverage optics. That sentence costs the author something and is why the gate table can be
  believed.

## Promote

`bash plugins/panel/tests/judges.test.sh && bash plugins/panel/bin/judges.sh` into `gates.yml` — the
same Promote as 002, half-landed: it reached the README's copy-paste line but not the file that
defines a gate.

## Challenge

- The brief's W3 line — "negative cases now resolve against `tests/agents/`" — is **overstated**.
  Two new fixtures do; four pre-existing negative fixtures do not. `charter:135-136` states the
  overstatement as fact.
- The fix to the defect disclosed in the brief is **incomplete**: two more copies carry it. In CI the
  two `ls-files` forms are equivalent on a fully-tracked checkout, so the exposure is local.

## Unverified

- Every gate result is taken from the parent; the judge ran nothing.
- Whether PR #54 already touches `gates.yml`. *Parent note, post-verdict: it does — confirmed with
  `gh pr view 54`. This branch descends from #54's, so the two new steps are a follow-on rather than
  a conflict, and a PR from here must target `feat/panel-convening`, not `main`.*
