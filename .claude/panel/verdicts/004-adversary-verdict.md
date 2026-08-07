# Verdict 004 — adversary — REVISE

Reviewed: `feat/verdicts-on-disk` @ **eba3ab8**. Round one for *an approval proves its own review*.
Recorded by the parent. 001 judged the sub-team model, 002/003 judged *judges are peers*; no
unresolved item from those survives against this deliverable, so **the ratchet does not bind**.

| Sev | Where | Issue | Change | Principle |
|-----|-------|-------|--------|-----------|
| C | `verdicts.py:75-83` | `recorded` is a set of role *stems* off the filesystem, never joined to the approval it proves — so the three verdicts of a **closed** charter satisfy the live charter's roster, one file per role satisfies any number of rounds, and once a repo has filed `001-adversary-verdict.md` the gate is green forever regardless of what the next run commits | scope the trail to its run: archive a closed run to `verdicts/<slug>/`, and require the live `approval.md` to name the charter | `charter:8`; `craft-oracle`, *A Green Gate Can Be Empty* |
| W | `verdicts.py:32-36` | `rpartition(":")[2]` collapses `plugin:role`, so two seats sharing a stem are discharged by one file; `panels/partial` uses distinct stems, so the case has no input | key on the full name, or `die(USAGE)` on collision | `craft-oracle` — the inputs dodge the failure mode |
| W | `verdicts.test.sh:31-36` | two documented behaviours unexercised: the digit lookahead (`defaced` is valid hex) has no fixture, and `$PANELS/no-charter` **is not on disk** — that row tests a missing path, not a charterless directory | add both fixtures | `craft-oracle`, audit a gate by breaking the code on purpose |
| W | `README.md:54` | "Five gates" above an **eight-row** table — the count defect 003 W4 raised and `approval.md` records as corrected, reintroduced | drop the count | fix-induced regression; recurrence of 003 W4 |
| W | `gates.yml:38-57` | five panel steps across two charters, **none ever executed**, while the CI lock is now stated a third time | make `README` the definition and `gates.yml` a mirror | `craft-verdict` — approved over three times, raise the accumulation |
| W | `plugins/panel/README.md:83` | the `Checked` block names only `judges.sh`; the plugin ships a second checked mechanism at 0.8.0 | add `verdicts.sh` and its exit contract | `CLAUDE.md` — after modifying a plugin, check the README |

## What's Good

- `charter.py:31-44` — one parser, and it *refuses* two `## Panel` sections rather than picking one.
  The fence-decoy defect cannot be reintroduced in one gate and not the other.
- `judges.py:114-117` survived a wholesale rewrite intact: the Law 4 sentence still prints only when
  the law broke. Rewrites are where that nuance dies.
- `verdicts.test.sh:41-44` — the zero-assertion guard carried into the new suite as structure rather
  than memory. "127 is non-zero" is now a property of every suite panel ships.

## Promote

A loop asserting every fixture path an `it` row names exists on disk — third instance this session
of a gate trusted on its exit code while handed nothing.

## Challenge

- **The brief understated C1.** It framed the stale `approval.md` as a today-only artefact. It is
  permanent: after this charter closes, every subsequent run passes on files already committed,
  including a run that commits zero. `bulibeef`'s exact shape, surviving inside the gate built to
  catch it.
- **`charter:26` and `:62` are satisfied vacuously** — "run against this one it passes" was true on
  the *previous* charter's trail, and the done-when could not tell that pass from a real one.
- The brief said four workflow steps; `gates.yml` holds five.
- `python` rather than `python3` matches repo convention. Whether it resolves on `ubuntu-latest` is
  **unverified** — nothing has ever run there.

## Disposition

**Critical fixed, all five Warnings addressed.** The trail is now scoped to its run: `approval.md`
must name the charter it approves, and the closed run is archived to `verdicts/judges-are-peers/`.
Demonstrated — restoring the stale approval now fails with *"does not name this charter"*.

Suite 6 → **9 assertions**, adding `foreign-approval`, `defaced`, `stem-collision`, and a real
`no-charter` directory that git can carry. Both suites now refuse to score a row whose fixture is
absent, which is the `Promote` above, landed in the same round it was raised.

**Not closed.** A Critical stood, so a round is forced. Round two judges the fixes.
