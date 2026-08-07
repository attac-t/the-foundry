# Verdict 005 — adversary — REVISE

Charter: an approval proves its own review
Reviewed: `feat/verdicts-on-disk` @ **fcbe8de**. Round two, ratchet binding. Recorded by the parent.

All five Warnings from 004 and C1-as-prescribed verified fixed. One regression the fix introduced
blocks.

| Sev | Where | Issue | Change | Principle |
|-----|-------|-------|--------|-----------|
| C | `verdicts.py:102-103` | the gate requires `approval.md` to contain the charter title and **no shipped instruction says so** — `craft-verdict:61` and `adversary.md:91` both specify "branch, commit, rationale, residual risks". An approval written exactly to spec passed before `fcbe8de` and exits 1 after it, in every repo that installs panel, on its first approval | add the charter name to `craft-verdict:61` and `adversary.md:91`; bump | fix-induced regression; `craft-oracle` — a gate nobody agreed gets overridden |
| W | `verdicts.py:49-55, :61` | C1's core sentence is still literally true — `recorded()` joins nothing to the run; the join is a human `mv`. `:61` says "Archive **it**", the approval, while `panel/README:182` says archive the run. Move only the approval and the closed run's verdicts discharge the live roster | make `:61` say the run: approval **and** every `NNN-<role>-verdict.md` | unresolved remainder of 004 C1 |

## What's Good

- `verdicts.py:39-45` — a stem collision exits **2**, not 1: the filename cannot carry the
  distinction, so nothing is certified either way. A rewrite that "helpfully" picked a winner would
  lose the difference between wrong and undecidable.
- `verdicts.py:24` plus `panels/defaced` — the lookahead now has an input that fails without it. The
  regex can no longer be simplified by someone who reads it as redundant.
- `verdicts.test.sh:19-22` — no severity carve-out. A deleted fixture fails its row instead of
  scoring it.

## Promote

`recorded()` counting only verdicts whose text names the charter — closes the archive hole with no
human step. `004-adversary-verdict.md:3` already names it, so the convention exists to gate.

## Challenge

- **The brief overstated W2.** `judges.test.sh:27` exempted every `want=2` row from the existence
  guard — necessary for `nothing-of-this-name.md`, but it also unguarded `no-panel-section.md` and
  `two-panel-sections.md`, which exist and would have scored for the wrong reason if deleted.
- **Disclosure 1 understated itself.** `charter:62` is vacuous *until* the approval lands, which is
  the first moment it is tested for real — and the Critical above is what fires there.
- `plugins/panel/bin/__pycache__/charter.cpython-314.pyc` appears in `.git/index`, and `__pycache__`
  is absent from `.gitignore`. *Inferred from a binary grep; the judge cannot run `git ls-files` —
  unverified.*

## Disposition

**Critical fixed. Warning dissolved rather than patched, by taking the `Promote` in the same round
it was raised.** `recorded()` now counts only verdicts whose text names the charter, so the join is
textual and archiving is housekeeping — move half a run, or none of it, and last charter's verdicts
still discharge nobody. `craft-verdict:56-70` and `adversary.md:91` now require the name in both
artifacts, so the gate asks for something the shipped instructions ask for too.

Both challenges verified and acted on. The `want=2` exemption is replaced by an explicit `absent()`
helper that **fails if the fixture exists**, so the one deliberately-missing row cannot silently
become a live one. **The `__pycache__` claim was correct** — `charter.cpython-314.pyc` was tracked
inside a shipped plugin. Untracked, deleted, and `.gitignore` now carries a rule.

Panel `0.8.1` → `0.9.0`: the approval format gained a required element.

**Not closed.** A Critical stood. Round three judges these fixes.
