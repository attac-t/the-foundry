# Charter: cross-plugin convening

## Goal

**The core roles are constitutional. Stack plugins contribute sub-teams, not peers.**

`author`, `adversary` and `newcomer` are the roles. Each owns a moment and owns the verdict for
that moment — the adversary judges correctness, the newcomer judges comprehension, the author
writes and never judges. That structure does not change when a plugin is installed.

What a stack plugin contributes is a **lens inside an existing moment**: a specialist convened
alongside a core role, returning *findings* into that role's verdict, never a verdict of its own and
never an approval. A test-quality specialist sharpens the adversary's moment; it does not become a
second adversary.

Stated so it could be false: on a machine where a stack plugin ships a specialist, `/panel` proposes
it as a lens under the role whose moment it sharpens, **displays its tool scope**, and the resulting
run produces exactly as many verdicts as there are core roles engaged — not one per agent. Today
`/panel` names `author, adversary` in every repo regardless of what is installed.

**The property that must hold: the protocol does not grow with the roster.** Ten specialists must
cost ten lenses and zero new rules. A design where each new agent adds a termination case is the
wrong design, however useful the agent.

**Availability is not eligibility.** `kernel:architect` declares no `tools:` — it inherits
everything, so it can write. Seating it as a judge would void Law 4. A candidate lens is one whose
frontmatter restricts its tools; the proposal displays the scope so the human enforces the rule
rather than rubber-stamping it.

## Stated assumption

**The harness supplies the parent session with the list of available agent types.** This is the
premise the whole mechanism rests on, it appears nowhere else in the repo, and **no gate can catch it
being false** — the parent can see the list; nothing it writes can prove the list was not invented.
If it is false, discovery has no foundation and the design reverts to naming agents by hand.
Confirmed by the human at approval, or the charter does not pass.

**The proposal step has no mechanical oracle.** Whether a proposed panel is a *good* panel is
judgement. The gates below check that the instruction and the example exist, not that the proposal is
sound. Recorded here rather than left implied — `craft-oracle`, The Coverage Rule.

## Done when

**Goal gates must exit non-zero at this charter's base commit.** One already satisfied before work
begins certifies nothing. Verified — all four fail at base:

- [ ] Goal: `grep -q 'available in this session' plugins/panel/skills/craft-charter/SKILL.md`
- [ ] Goal: `grep -A8 '^## Panel' plugins/panel/skills/craft-charter/SKILL.md | grep -q 'pest:'`
      — the worked example names an agent outside panel
- [ ] Goal: `ls plugins/pest/agents/*.md`
- [ ] Goal: `grep -q '^skills:' plugins/pest/agents/*.md` — a judge sharing the adversary's
      vocabulary *is* the adversary; pest's judge must name pest's own

**Standing gates must exit zero at base and still exit zero at the end.** They guard against
regression, so the base-commit rule inverts for them. `repeats` is scoped to the two plugins that
are clean; unscoped it fails on 16 pre-existing repeats elsewhere, and a gate that is red for
unrelated reasons is one nobody trusts.

- [ ] Standing: `bash bin/repeats.sh $(git ls-files 'plugins/panel/*.md' 'plugins/pest/*.md')`
- [ ] Standing: `bash bin/versions.sh`
- [ ] Judged: `panel:adversary` approves, with residual risks recorded

## Out of scope

- `laravel-ddd` and `laravel-playbook` agents — one charter each.
- Panel growing further agnostic experts of its own — own charter.
- **Multi-judge termination.** `craft-verdict` is written for one judge writing `approval.md`; two
  judges can approve past each other's REVISE. Real, and not fixable here. Named, deferred.
- **Any change to judge tool restrictions.** Both convening points already run in the parent
  session, so no judge needs to spawn anything. `Read, Glob, Grep` stays.
- A role registry or capability vocabulary. Zero consumers; speculative.

## Panel

`panel:adversary`

## Approved

<pending — human>
