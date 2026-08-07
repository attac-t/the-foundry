# Verdict 002 — adversary — REVISE

Reviewed: `feat/panel-convening` @ **uncommitted working tree — no SHA**. Recorded by the parent,
not the judge. Charter: *judges are peers*, approved 2026-08-07.

Round one for **this** charter. Verdict 001 judged the sub-team model, which this charter rejects
and replaces; none of its findings survive as unresolved items. The ratchet does not bind.

| Sev | Where | Issue | Change | Principle |
|-----|-------|-------|--------|-----------|
| C | `judges.sh:57-63` | `plugin:agent` does not pin — a missing pinned path falls through to `rglob`, so `pest:adversary` resolves to *panel's* adversary and exits 0 | return `None` when `plugin` is set and pinned is absent; fixture `wrong-plugin.md` → **1** | `judges.sh:53` claims pinning; `charter:123` claims rejection |
| C | `judges.sh:90` | `gates[label] = …` assigns, not appends — two lines sharing a label silently drop the first, so a writer listed first exits 0 | `gates.setdefault(label, []).extend(…)`; fixture `repeated-label.md` → **1** | `charter:112` |
| C | `tests/fixtures/*` | no fixture carries a fence, a following `##`, or a second `## Panel` — the three constructs every real charter has, and the blind spot that let a total mis-parse still score 7/7 | fixture whose fenced example seats a restricted judge and whose real section seats `kernel:architect` → **1** | `craft-oracle`, *A Green Gate Can Be Empty*; `charter:142` falsified |
| C | `charter:181-184` | records the CI lock but not the weakening in force — this verdict cites no SHA, against `author.md:68` and Law 5 | add the line to `## Gates weakened`, or commit before `/verdict` | `craft-charter:95-106` |
| W | `charter:113` | contract promises `2` for "unreadable"; `judges.sh:36` `read_text` raises instead, and no assertion exercises `2` at all | guard the read → 2; fixture with no `## Panel` → **2** | `charter:104` |
| W | `plugins/panel/tests/` | the seven want/got pairs exist only in shell history — the goal oracle is not an artifact and cannot be re-run identically next round | commit `tests/judges.test.sh` exiting 0/1; add to `README:64` | `craft-oracle`, "an oracle is a command" |
| W | `fixtures/judge-can-write.md:6` | panel's oracle breaks if kernel renames an agent; `PANEL_AGENT_PATH` (`judges.sh:47`) was built for this and no fixture uses it | point the negative fixtures at a local agent dir | `decide-boundary:36` |
| W | `charter:150-151` vs `:211` | "`pest:critic` sharpens gate 1", yet `## Panel` seats only `panel:adversary` — the shipped judge is unexercised by the run that ships it | seat it, or state it applies to runs that have a suite | `craft-charter:16-17` |
| W | `charter:12-13` | "no plugin references another" is verified only over `dependencies` and `skills:`; `critic.md:71` names `panel:craft-verdict` and `pest/README:57` names panel | narrow the sentence to what was checked | `adversary.md:42` |
| N | `judges.sh:43` | `sections[-1]` silently picks the last of several `## Panel` sections — a second, untested mechanism masking the same defect as the fence row | fail on more than one section, or fixture it | `craft-oracle`, *A Green Gate Can Be Empty* |

## What's Good

- `judges.sh:118-134,146-150` — separates `unresolved` from `law4` and prints the Law 4 sentence only
  when the law actually broke; a typo is not dressed as a violation.
- `judges.sh:95-116` — diagnoses the *shape* it found and prints the format to replace it. The only
  charters in existence are the unlabelled shape, and they get advice they can act on.
- `charter:104-115` — caught its own green-but-empty gate (`127` satisfying "non-zero") and recorded
  it before shipping. Verdict 001's `Promote` landed as the deliverable, and its `Challenge` landed
  as a charter section. The memory mechanism operated.

## Promote

`bash plugins/panel/bin/judges.sh` over every charter in the repo, in the standing gate line — the
check has a consumer today and runs only when someone remembers.

## Unverified

- The `7/7`, STANDING and LIVE results are taken from the brief; the judge ran nothing.
- Whether the harness can seat `pest:critic` at all. `judges.sh` certifies a file, not a seatable
  agent type.

## On legitimacy

Reviewing an unanchored tree is legitimate to *perform* — a definite state was read and every
citation is `file:line`. It is **not** legitimate to *close*: an APPROVE with no SHA cannot satisfy
Law 5, and the next judge cannot reconstruct what this one read.

## Disposition

**Author response — all four Criticals fixed, six of six W/N addressed.** `judges.test.sh` now holds
**15 assertions**, up from 7; `wrong-plugin` and `repeated-label` fail against the pre-verdict code
and pass against the fix. `fenced-decoy` is a regression guard for a defect already closed.

**Found while discharging W2, and neither the judge nor the brief caught it:** the scoped `repeats`
invocation used `git ls-files`, which lists **tracked files only**. Every file this charter produced
was untracked, so the gate reported PASS over 36 files while reading none of the new work — the
evidence that `pest:critic` does not duplicate panel's prose was never gathered. Fixed to
`git ls-files -co --exclude-standard` in both the charter and `README`; the real figure is **53
files, PASS**.

This is the fifth defect this session where a gate was trusted on its exit code without checking
what it had been handed. It is the same shape as C3.

**The charter cannot close on this verdict.** REVISE stands until the work is committed and re-judged
against a SHA.
