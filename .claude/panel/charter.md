# Charter: judges are peers

Supersedes the sub-team model, rejected by
[verdict 001](verdicts/001-adversary-verdict.md). See `## Rejected`.

## Goal

**Judge eligibility is a property of an agent, not a dependency of it. Law 4 becomes an exit code.**

An agent whose `tools:` is restricted to `Read, Glob, Grep` cannot write what it judges. That is
Law 4 stated as frontmatter every plugin already writes for its own reasons. Panel reads it. The
agent never learns it is a judge, so **no plugin declares a dependency on another** — verified over
exactly two things and no more: zero declared `dependencies`, and every agent's `skills:` naming
only its own plugin's skills. Prose references remain and are deliberate — `critic.md` names
`panel:craft-verdict`, `pest/README` names panel — matching
`laravel-ddd/skills/polish/SKILL.md:84`. They degrade to nothing when the other plugin is absent,
which is the property that matters; "references" unqualified would have been a wider claim than was
checked.

**The builder is never the judge.** An architect that cannot write is not an architect; a judge that
can write is not a judge. Law 4 makes them disjoint by construction, so a plugin contributing a
judge ships a *second* persona rather than reusing its builder — the split panel already has between
`author` (no `tools:`) and `adversary` (`Read, Glob, Grep`). `kernel:architect` inherits `Write` and
`Agent`; seating it would void Law 4 silently, and `judges.sh` is what makes that loud.

Stack plugins therefore contribute **peer judges** — same class as `panel:adversary`.

**`## Panel` names moments, not roles**, because that is where a judge's authority comes from:

```markdown
## Panel
author:  panel:author
gate 1:  panel:adversary
gate 2:  panel:newcomer
```

A stack judge joins a gate. Sharing a gate means judging the same moment, so those judges must
agree; holding its own gate means it accumulates independently. **Termination needs no new rule —
it falls out of the format.**

Taken from a real run, not designed: `bulibeef@6535d4eb` records this structure in `approval.md`
*after the fact* — *"`panel:adversary` (gate 1) · `panel:newcomer` ×4, each fresh (gate 2)"* — while
its charter's `## Panel` is a flat list. The information exists; it is written in the wrong file, at
the wrong time, by the wrong artifact.

## Prior art

Not a new shape. Google requires three approvals per change, each certifying something different —
**LGTM** (*"correctness and comprehension"*), **code owner** (appropriate for this part of the
codebase), **readability** (conforms to the language's style). Two consequences are load-bearing
here and neither was designed:

- *"most reviews have one person assuming all three roles"* — **gates are named by mandate, not by
  person**, so one agent may hold several and `newcomer` ×4 costs no rule.
- *"the author can also assume the latter two roles, needing only an LGTM from another engineer"* —
  **independence attaches per gate, not globally.**

Panel is deliberately stricter than Google: no gate is self-certifiable. The reason is not rigour
for its own sake — an LLM is sycophantic toward its own prior output in a way a human author is not,
so the cheap self-certifications Google permits are the ones that degrade first.

**Fagan (1976)** supplies exit authority: a moderator declares exit against predefined criteria and
the author may not moderate. **Gilb & Graham (1993)** make the defect log a required artifact of the
process, not a by-product — the point the *out of scope* note below turns on.

**Disagreement is normal.** Divergent review scores appear in **15–37%** of multi-reviewer patches
(OpenStack/Qt), negative-following-positive in **70%** of cases, and unresolved divergence does not
stall — it abandons work. `DEADLOCK` is a first-class path, not an edge case.

**The tool check is an allowlist.** `ADR-001` — a denylist is a guess about the tool surface, and the
surface changes every release. A judge needing a fourth tool fails this gate and a human decides.
That is the gate working, not a false positive.

## Rejected

The sub-team model — specialists returning findings into another role's verdict, issuing none of
their own.

Its purpose was to avoid multi-judge termination. Everything it cost was downstream of that
avoidance: a third delegation primitive over kernel's two (`ground-delegation:29`), a findings
channel with no format running through the parent that drove authoring, and a declaration site the
same charter called speculative at its own `:71`.

**Also rejected: this charter's own conjunction rule — *"every judge must approve"* — falsified by
the only production run in existence.** `bulibeef`'s round 4 closed with `panel:adversary` at
APPROVE and `panel:newcomer` at REVISE holding a Critical; the human signed, and that Critical became
residual risk 9. The conjunction would have refused a correct approval. Judges of *different
moments* accumulate; only judges of the *same* moment must agree, and panel's two never shared one.
Verdict 001 and this charter both over-sized the problem.

Falsified twice: Google's rule is every gate approved **and zero unresolved comments** — and
*resolution is not agreement*. An accepted residual risk is resolved. That is precisely what round 4
did, and it is the rule `craft-verdict` gets instead of the conjunction:

> A run closes when every gate has approved and no finding is left unresolved. A finding is resolved
> when it is fixed, withdrawn, or **accepted as recorded residual risk — which only the human may
> do.**

Rejected from earlier drafts: deriving judge status from loading `craft-verdict` (it would have been
the repo's first load-bearing cross-plugin reference, and it missed any judge that forgot the skill);
and gates that grep for a sentence, replaced below.

## Done when

**Assertions, not greps.** Each names one behaviour and would fail for a plausible wrong
implementation — `pest:ground-suite:13`, `panel/agents/author.md:38`.

**Each asserts an exact exit code, never "non-zero".** Drafted the loose way, three assertions
passed at `1d9708e` on the *absent* script: `127` is non-zero, so "it rejects a judge that can
write" was satisfied by there being nothing to reject with. `craft-oracle`, *A Green Gate Can Be
Empty* — reproduced inside the gates written to prevent it. The contract closes it:

| Exit | Means |
|------|-------|
| `0` | every named judge is eligible |
| `1` | a named judge is ineligible, or the charter names none |
| `2` | usage — charter missing, unreadable, or no `## Panel` to parse |

Verified: every assertion below fails at `1d9708e`, which observes `127`.

### Law 4 as an exit code

- [x] `bash plugins/panel/tests/judges.test.sh` → **0** — fifteen assertions, one per behaviour

**The suite is the artifact, not the run.** Drafted as inline `want/got` pairs, the assertions lived
only in shell history — unrepeatable next round, and not an oracle by `craft-oracle`'s definition.
The runner also errors on zero assertions collected, because a suite that gathers nothing still
exits 0.

**Seven of the fifteen exist because a judge read this.** The original set was seven copies of one
fixture shape, and that shape omitted the fence, the second `## Panel`, and the cross-plugin pin —
so a *total* parse failure still scored 7/7. It now carries the constructs a real charter has.

Fixtures carry no prose; `repeats.sh` scans them, and that is the oracle correctly forcing them
minimal. Negative cases resolve against `tests/agents/`, so panel's gate does not break when another
plugin renames an agent.

### The judge speaks its own plugin

- [ ] it argues from pest's laws, not panel's —
      `bash bin/repeats.sh $(git ls-files -co --exclude-standard 'plugins/panel/*.md' 'plugins/pest/*.md')` **zero**

A standing gate doing double duty. It is what old gate 4's `grep -q '^skills:'` was reaching for and
could not express.

### Moments, not a flat roster

Covered by the suite above — `two-gates`, `writer-on-gate-2`, `repeated-label`. A `## Panel` format
nothing can parse fails most of the fifteen, so it needs no gate of its own.

**One judge may hold a gate more than once.** `bulibeef` ran `panel:newcomer` ×4, each fresh, and
the series is what produced the strongest findings in that run. The format must not forbid it —
checked by `two-gates.md`, not by a rule.

### Judged, not gated

**Whether a gate assignment is *right* has no oracle.** That `pest:critic` sharpens gate 1 rather
than deserving its own is judgement. Declared, not dressed as a grep — `craft-oracle`, The Coverage
Rule.

**`pest:critic` is not seated on this run, deliberately.** It judges Pest suites and this repo has
none; seating it here would be a judge with nothing to read, which is theatre rather than review.
Its eligibility is certified by the `pest-critic` fixture, and it is exercised the first time a
charter runs against a project that has a suite. **Shipped-but-unexercised is a real gap** — it is
recorded rather than dressed up as coverage.

- [ ] Judged: `panel:adversary` approves, with residual risks recorded

### Standing

Exit zero at base and must still exit zero at the end. `repeats` is scoped to the two clean plugins;
unscoped it fails on 16 pre-existing hits elsewhere, and a gate red for unrelated reasons is one
nobody trusts.

- [x] `bash bin/frontmatter.sh`
- [x] `bash bin/versions.sh`
- [x] `bash plugins/panel/bin/judges.sh` — this repo's own charter, promoted from verdict 002's
      `Promote`. The check had a consumer and ran only when someone remembered.

## Stated, ungated

**The harness supplies the parent with available agent types.** Observed directly in the session
that wrote this charter: `panel:adversary`, `panel:author`, `panel:newcomer`, `kernel:architect`.
Zero stack-plugin agents, which is why the `## Panel` field looks closed. It is open; nothing exists
to name. No gate can catch this being false — a session cannot prove its own system prompt to a
script.

**`judges.sh` ships inside the plugin**, at `plugins/panel/bin/`, so it has a consumer beyond this
repo. Residual risk: a panel user must invoke it by its installed path, which is awkward and
unaddressed here.

**Boundary.** The pest judge survives alone and is arguably its own charter. It stays because the
gate and the termination rule have zero consumers without it. `decide-boundary` — needed twice, not
zero times.

## Gates weakened

**GitHub Actions is billing-locked on this account. No workflow can obtain a runner.** Every gate
above is self-run locally and reported as such. A green result here is one machine, once — not CI.

**Gate 4 ran against an uncommitted working tree, so its verdict cites no SHA.** `author.md:68`
requires one and Law 5 requires the verdict to be an artifact of the branch under review; neither
holds while the work is unstaged. The review was still worth performing — it read a definite state
and every finding carries `file:line` — but it **cannot close the charter**. A later judge cannot
reconstruct what this one read. Survivable once, declared here rather than discovered later.

## Out of scope

- `laravel-ddd` and `laravel-playbook` judges — one charter each, each shipping a *new* restricted
  persona rather than reusing a builder.
- **Discovery or proposal machinery in `/panel`.** `craft-charter:88` forbids inferring the panel.
  The human names it; that is the design, not the defect.
- Panel growing further agnostic agents of its own.
- **The parent's unconstrained write scope** — Law 1's known gap, disclosed in `README:37`.
- Changing judge tool restrictions. This charter *checks* them.
- **A gate forbidding cross-plugin frontmatter references.** The invariant is real and holds by
  practice; promoting it to an oracle is Law 8 and its own charter.
- **The ratchet versus Fagan's follow-up.** Fagan re-inspects *fully* when rework is non-trivial;
  panel's ratchet permits only unresolved items and fix-induced regressions, so a large rework gets
  a narrow re-read. A real conflict with the canon, and panel has no size trigger. Its own charter.
- **Verdicts not reaching disk.** `bulibeef`'s completed run left `approval.md` and
  `cold-read-log.md` but **no `NNN-<role>-verdict.md`** — eight judgements across four rounds, none
  committed, so Law 5 and the memory mechanism never operated on the only production run. Verdict
  001 raised the same Challenge here. **Observed twice, independently — a Law 8 promotion candidate
  and a larger defect than anything this charter fixes.** Its own charter, and it should go first.
- **Extracting the toothless-suite tells into a `pest:ground-*` skill.** Needed once, by the critic;
  `decide-boundary:50` wants twice. They live in the persona body until `craft-test` wants them.
- PR #54, open on this branch for unrelated CI work.

## Panel

author:  `panel:author`
gate 1:  `panel:adversary`

## Approved

Chris Attard — 2026-08-07
