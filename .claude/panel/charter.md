# Charter: a green check is two claims

Follows `an approval proves its own review`, closed 2026-08-07 — see
[its approval](verdicts/an-approval-proves-its-own-review/approval.md).

## Goal

**A passing check asserts two things and only one of them is on screen.** *The check succeeded* is
printed. *The check was pointed at the thing* is not, and it is the half that fails.

Nine times in one session a gate was green and measuring nothing or the wrong thing — a string
instead of a behaviour; `127` from an absent script satisfying "non-zero"; a parser reading the
fenced *example* of a section rather than the section; `git ls-files` excluding exactly the work
under review; a count of **arguments** printed as a count of files while subprocesses died of fork
exhaustion; a fixture passing for a reason other than the one it existed for; a corpus that stopped
being evidence when someone else's repository moved. Four more were found by a judge and not by the
author, every one of them exit-0-where-it-should-fail.

Three deliverables, one question — *why did the thing I checked not reflect the thing that runs?*

1. **`kernel:ground-evidence`** — what a green check does not prove, and how to read one. The
   material above, generalised past this repo. Kernel rather than `panel:craft-oracle`, because it
   governs any automated check and `craft-oracle` only reaches people who installed panel.
2. **`kernel:ground-mechanism` gains the authoring altitude.** It already answers *code or model* and
   carries the promote/demote migration. It does not answer the narrower question a plugin author
   actually faces: when does a rule earn `bin/x.sh`, and when does it stay pseudo in a `SKILL.md`?
3. **`kernel:craft-plugin-update` gains the cache.** `CLAUDE.md` mandates that skill after touching
   any plugin, and it says *bump, commit, push* without saying that the running copy is a **copy**.
   Installs are staged into a version-named cache directory pinned to a commit, so editing the tree
   changes nothing until `claude plugin update` and a session restart. **Every agent in the session
   that produced this charter judged panel `0.6.2` while the tree stood at `0.9.4`.** It also makes
   the bump rule load-bearing rather than bookkeeping: the cache directory is named by version, so
   without a bump an update has nowhere to land.

Stated so it could be false: `bin/repeats.sh`, widened to cover the three kernel files, exits **0**.
It exits 1 today.

## Why one charter

`decide-boundary`: (3) survives alone and is the split worth considering. It stays because all three
answer one question, and because (3) is the instance that produced (1) — a session could not see
what it was running, and nobody noticed for a day.

## Done when

**The mechanical surface here is thin, and saying so is the subject.** These deliverables are prose.
A gate can check that a skill registers, and that it does not restate a sentence another skill
already owns. Whether it is *right* is judged, by two gates, and no grep is dressed up to look
otherwise — `craft-oracle`, The Coverage Rule.

Goal gates, verified failing at this charter's base commit `d83a0bd`:

- [ ] `bash bin/repeats.sh $(git ls-files -co --exclude-standard 'plugins/panel/*.md' 'plugins/pest/*.md' 'plugins/kernel/skills/ground-evidence/*.md' 'plugins/kernel/skills/ground-mechanism/*.md' 'plugins/kernel/skills/craft-plugin-update/*.md')` → **0**

  Fails at base with **2** repeats: `ground-mechanism/examples.md` already shares two sentences with
  `craft-oracle`, across precisely the boundary this charter writes over. **Kernel prose has no
  duplication gate at all today** — the scoped invocation covers `panel` and `pest` only.

- [ ] `ls plugins/kernel/skills/ground-evidence/SKILL.md`
- [ ] `grep -q 'ground-evidence' plugins/kernel/agents/architect.md` — sub-agents do not inherit
      skills, so an unregistered one is a skill the architect cannot reach

Standing — exit zero at base and still at the end:

- [ ] `bash bin/frontmatter.sh`
- [ ] `bash bin/versions.sh`
- [ ] `bash plugins/panel/tests/judges.test.sh`
- [ ] `bash plugins/panel/tests/verdicts.test.sh`
- [ ] `bash plugins/panel/bin/judges.sh`
- [ ] `bash plugins/panel/bin/verdicts.sh`

Judged:

- [ ] **Gate 1** — `panel:adversary` approves, with residual risks recorded
- [ ] **Gate 2** — `panel:newcomer` reads `craft-plugin-update` cold and answers one question:
      *after editing a plugin, what must happen before the change is running?* Four timings appended
      to `verdicts/cold-read-log.md`

**Gate 2 is the real test of deliverable 3**, whose success condition is a stranger knowing what to
do. It is also the first two-gate run in this repository: `panel:newcomer` has never been convened
here, and the moments format has never carried a second gate outside a fixture.

## Stated, ungated

**No check available here can show that a skill changes behaviour.** Whether `ground-evidence` makes
the next session read a gate differently is unmeasurable at this scale. The honest instrument is the
cold-read series, and one reading is noise.

**The duplication gate catches verbatim repeats only.** Two near-identical sentences differing by a
word pass it. Restating `craft-oracle`'s ideas in fresh words is exactly what this charter must do,
and exactly what the gate cannot tell apart from drift.

**`bulibeef` is not evidence.** It moved once already. Nothing here asserts against it.

## Gates weakened

**GitHub Actions is billing-locked. No workflow can obtain a runner.** Every result is self-run, one
machine, once. Five panel steps in `gates.yml` have never executed, and whether `python` resolves on
`ubuntu-latest` is still unverified.

## Out of scope

- **Widening `repeats.sh` to the whole repo.** 18 pre-existing hits across `kernel`, `laravel-ddd`
  and `laravel-playbook`; a gate red for unrelated reasons is one nobody trusts. This charter widens
  it to the files it touches and no further.
- **Automating the plugin reinstall.** Documenting the cache is the deliverable; a hook that
  reinstalls on edit is its own charter and its own risk.
- **The ratchet versus Fagan's full re-inspection on non-trivial rework** — still unowned.
- **`laravel-ddd` and `laravel-playbook` judges** — one charter each.
- PR #54, and the two branches this one descends from.

## Panel

author:  `panel:author`
gate 1:  `panel:adversary`
gate 2:  `panel:newcomer`

## Approved

Chris Attard — 2026-08-08, on the words *"proceed with all three in one charter"*, with the split
question delegated back and decided against.

Recorded as what the approval rests on rather than as a stamp, because `craft-charter` says an
`Approved` line filled in by anything other than a person is the plugin lying to itself, and a
quoted instruction can be checked where a signature cannot.
