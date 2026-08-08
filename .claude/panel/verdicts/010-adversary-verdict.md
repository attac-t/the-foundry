# Verdict 010 — adversary — REVISE

Charter: a green check is two claims
Reviewed: `feat/ground-evidence` @ **0af4526**. Gate 1, round one. Ratchet does not bind.
Recorded by the parent.

| Sev | Where | Issue | Change | Principle |
|-----|-------|-------|--------|-----------|
| C | `gates.yml:32` | the widened repeats scope landed in `README:58` and `:65` only; `:32` is still `panel`+`pest`, `:24-26` still says kernel is excluded, `README:55` claims the workflow "mirrors it", and `README:77` says the gates check nothing about `kernel` at all | widen `:32`, rewrite the comment, reconcile `README:77` | `craft-oracle` — a re-specified command drifts; **second occurrence**, ruled a W in `judges-are-peers/003` and closed once already |
| W | `ground-mechanism/examples.md:56-73` | a reworded near-copy of `craft-oracle/examples.md:101-118` — same example, same **30–60%**, same trailing clause. It clears the verbatim gate by word substitution, then defers to panel for "the measured breakdown" after printing it | cut to the pointer, or use an instance panel does not carry | `charter` — the gate cannot tell restatement from drift |
| W | `craft-plugin-update:50-51` | "the one gate that reads this repository's prose does not cover `kernel`" — `README:65` covers this very file; true only of the stale workflow | drop the clause | `ground-evidence` — assert the reason, not the shape of it |
| W | `craft-plugin-update:68`, `ground-evidence/examples.md:3-4` | shipped kernel prose cites *this* repo as evidence — `bin/versions.sh`, "every fix is in the repository's history". A reader who installed kernel elsewhere has neither | name the guard generically, or mark the provenance | `decide-boundary`, *does it stay correct alone?* |
| W | `kernel/README.md:34-45` | the Skills index lists 27 of 32; `ground-evidence` joins five already missing | index all of them | a deliverable nobody can find is one nobody reads |

## What's Good

- `ground-mechanism:66-68` — the script's *bill*: it must itself be trusted. The only argument in the
  section cutting against writing one, and the half that stops gate proliferation.
- `craft-plugin-update:70-72` — states its own gate's under-coverage inside the document that would
  otherwise be quoted as proof.
- `cold-read-log.md:14-19` — route notes, not only timings. Row two becomes comparable rather than
  merely appended.

## Promote

`bin/gates-agree.sh` — assert the workflow's steps and the README's line name the same commands.
Second occurrence of this drift; the first was `judges-are-peers/003`.

## Challenge

- **`charter:60-61` states a false reason.** *"Sub-agents do not inherit skills"* is contradicted by
  `craft-skill:46-49`: *"a preload list, not an allowlist. Omitting a skill does not deny it."* The
  gate is defensible; the justification was not.
- **Version bump unverified** — `1.9.1` is a patch number where a new skill wants a minor. No gate
  here can read history.
- SPLIT considered and declined: kernel and panel each install standalone, so the `craft-oracle`
  overlap cannot be extracted anywhere. W1 is ownership, not a boundary.

## Disposition

**Critical fixed.** `gates.yml` widened, its scope comment rewritten, and `README`'s two
contradicting claims reconciled — the gates now say they reach three kernel skills and no further.

**The `Promote` landed in-round as `bin/gates-agree.sh`**, which failed its own first run by
selecting the README's *install* fence instead of the gate line. Fixed, then broken on purpose to
confirm it reports the missing step. It is now the first gate in both files.

All five Warnings addressed. W1 was not repaired by rewording again — the passage is replaced with an
open-set example panel does not carry (comments that explain *why*), because rewording is the failure
mode the finding named. W4's citations are genericised; the kernel index now lists all 32 skills.

**Both challenges accepted.** The charter's registration gate now carries the true reason —
preloading puts the skill in context, it does not grant access. Version history verified:
`1.8.2` → `1.9.0` (minor, new skill) → `1.9.1` → `1.9.2`, correct.

**Not closed.** A Critical stood; round two judges these fixes.
