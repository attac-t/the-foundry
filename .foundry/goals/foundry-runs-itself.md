# Foundry runs itself

Foundry takes its own real work from direction to verified delivery, and the result informs the
next run.

Done when:

- A real change completes the supported workflow, from a declared requirement to a merged delivery.
- Required independent review can reject work, and a rejection blocks completion and delivery.
- A separate producer satisfies the same contract, so one build is not the whole proof.

State: partly, and less than it looked on 28 August 2026.

| Condition | Where it stands |
|---|---|
| the supported workflow, end to end | the requirement was declared, judged and the verdict consumed. **The merge was made by hand.** No run's delivery record names `f21e2b7`, so `deliver` was never the thing that landed it |
| a rejection blocks completion and delivery | proved in a fixture, at both `complete` and `deliver`. **Never proved on a real one.** The judge asked for a revision and the producer agreed — that is a producer being reasonable, not Floor refusing |
| a separate producer | unmet. One model has judged, and none has produced |

Five boundaries sit outside these three, and none of them is a condition here. The graded, delivered
and merged commit are not shown to be one lineage. The suite that ran is not shown to be the suite
that was pinned. No identity is authenticated. The verdict does not outlive the run directory.
Nothing stops a delivery made outside Floor. [Status](../status.md) already names four of them with
the issue that would close each.

**Meeting this goal removes one veto. It does not make Foundry ready elsewhere** — the accepted
words say *before*, not *therefore*.

No run has gone the whole way unwatched, and the panel is one member. Neither is a condition above.
Making either one is the owner's to do.

Accepted: 27 August 2026, by the repository owner. Recorded in
[the decision](../decisions/foundry-runs-itself-is-critical.md), which quotes the words they used.

Evidence: [#407](https://github.com/attac-t/the-foundry/pull/407),
[#408](https://github.com/attac-t/the-foundry/pull/408). Both are local-only; hosted checks are unpaid.
