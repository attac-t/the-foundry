# Verdict 001 — adversary — REVISE

Design under review: the **sub-team** model in `.claude/panel/charter.md`. Pre-implementation;
nothing built. Round one on the record — no `verdicts/` existed anywhere in the repo, so the ratchet
does not bind and the prior REVISE (chat only) was unreadable.

| Sev | Where | Issue | Change | Principle |
|-----|-------|-------|--------|-----------|
| C | charter:19 | the stated defect — `/panel` names `author, adversary` regardless of install — is the behaviour `craft-charter:88` prescribes, and :88 is never cited | cite :88 and argue proposal-with-display is not inference, or drop discovery and keep hand-naming | craft-charter:88 |
| C | charter:47-52 | the goal's three clauses (lens attachment, tool-scope display, verdict count) are ungated; gate 2 passes on `## Panel / author, adversary, pest:test-quality` — the flat roster this charter rejects | gate the nesting notation, and `^tools:` in the pest agent | craft-oracle, *A Green Gate Can Be Empty* |
| C | charter:12 | specialist findings enter the judge's verdict as parent paraphrase — no format, no rule, no gate; the parent is the context that drove authoring | specialist returns `craft-verdict` rows; adversary marks any row it did not verify, per `adversary.md:47` | ground-mechanism:8 |
| C | charter:71 | "a role registry — zero consumers" is falsified by gates 3-4 of the same charter, which create the consumer; attachment then lives only in parent memory | add `lens-of:` to the specialist's frontmatter, or name who decides and where it is recorded | charter:21 |
| W | charter:18 vs :67 | the goal grades on verdict count; out-of-scope defers the multi-judge termination that count produces | drop the count clause, or pull termination in | craft-charter:11 |
| W | charter:50-51 | gates 3-4 certify *panel's* role model by grepping `plugins/pest/*`; gate 4's `^skills:` passes on `skills: craft-verdict, craft-oracle` | split the pest specialist to its own charter, or grep for pest's own skill names | decide-boundary:36 |
| W | charter:5 | "sub-team" is a third primitive beside kernel's `sub-agent`/`agent team`, and `ground-delegation:51` routes "multiple lenses on the same artifact" to a **peer team** | reuse kernel's vocabulary, or state the override | ground-delegation:29,51 |
| W | charter:25-28 | `architect` is excluded but never placed; the one existing non-panel agent has no role in the model | state that write-capable agents are author-class, not lens candidates | charter:21 |

## The four claims the author could not substantiate

1. **"The protocol does not grow with the roster" — not false, unfalsifiable.** It does discriminate
   against the flat roster on termination: a lens issues no verdict, so it adds no case. But with no
   declaration site (C4), the invariant is checkable only by asking the parent what it remembered.
   **Survives as intent, fails as a stated property.**
2. **"Termination is solved" — the charter never claims it; the brief overstated.** Verified:
   `craft-verdict` contains no restriction to one verdict per gate, names a single `approval.md`
   (:59-61) and lists APPROVE (:66); `newcomer.md:64-65` writes its own verdict and :67-73 grants it
   Critical. Sequencing is inferred from `craft-spec:30`, which assigns *gates*, not approvals.
   Design survives only if the goal stops asserting verdict count.
3. **"Findings reach the verdict unsoftened" — worse than stated.** "attributed, not paraphrased"
   appears **nowhere** in the charter. There is not even the sentence.
4. **"`kernel:architect` has no home" — true.** It declares no `tools:`. The model has two attachment
   points and the author produces no verdict, so nothing can attach there. "Excluded" is coherent —
   but discovery's only current input is a rejection, and its only eligible input is invented by
   gates 3-4. `decide-boundary:50` — needed zero times, not twice.

**Pest.** Sub-team framing resolves the half previously warned about — a lens cannot become a second
adversary — and worsens nothing. It leaves the substance untouched: the adversary already loads
`craft-oracle`, which carries The Coverage Rule and *A Green Gate Can Be Empty*. Gate 4 was written
to answer exactly this and cannot.

**Boundary.** The rewrite reintroduced **multi-judge termination** (out-of-scope :67, graded at :18
and :22) and now holds something new — pest's specialist as a deliverable. SPLIT considered and
declined: the tells are downstream of C1, and three charters would each inherit the contradiction.

## What held

- :30-36 marks an unfalsifiable premise as unfalsifiable and routes it to the human — the exact
  pattern C3 should copy.
- :38-40 declares the proposal step has no oracle rather than inventing one.
- :44-46's fail-at-base rule is what made C2 findable. Verified: all four goal gates fail at base.

## Promote

`grep -L '^tools:' plugins/*/agents/*.md` — Law 4 eligibility as an exit code, not a display.

## Unverified

- Standing gates `bin/repeats.sh`, `bin/versions.sh` — no output handed over; not run.
- Branch mismatch between brief and session snapshot; unresolved without git.

## Challenge

`README:27` (Law 5) and `craft-verdict:46-48` require prior verdicts as committed input. **None
exist.** The memory mechanism in `README:142-149` is inoperative until a verdict is committed.
