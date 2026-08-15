# RFC-001: The Portable Composition Model

**Status:** Accepted — revision 12
**Plugin:** `floor`
**Author:** Christian Attard
**Date:** 2026-08-12
**Issue:** [#66](https://github.com/attac-t/the-foundry/issues/66)

---

## Abstract

Foundry's ideas are right and its contracts are prose. This RFC names the execution chain the model
was missing — **run, unit, workspace, session** — separates the *declaration* of a target from its
*checkout*, and turns the definition of good into an artifact whose clauses are **derived by code
where truth is mechanical, verified by an independent judge where meaning already exists, and
decided by a human only where new meaning appears.** Five contracts, all of them shapes rather than
files. No coordinator, no registry, no graph engine, no schema language.

Revision 2 converged with an independently written synthesis. Revision 3 answered an independent
architecture review that found the RFC's headline property — *the worker cannot lower its own bar* —
was not held by its own mechanism. Revision 4 adds the semantic derivation path, names the bootstrap
target, and settles the plugin name. **Revision 5 is the first amended by implementation evidence:
building the run and its targets falsified three statements this document made.** §6 records all of
it.

---

## Problem

### What works today

| Asset | Where | Why it matters |
|---|---|---|
| Convention resolution | `hooks/lib/resolve-memory.sh` | 23 lines, tested, degrades on no-git and detached HEAD |
| The code/model line | `kernel:ground-mechanism` | The load-bearing idea in the repo |
| Definition of good, already multi-part | `panel:craft-charter` | `Gate:` and `Judged:` clauses |
| Structural enforcement | `tools: Read, Glob, Grep` on judges | A judge genuinely cannot write what it approves |
| Defaults in one place | `signal/lib/score.awk` | A test forbids naming a default twice |

Foundry has zero GitHub coupling. Neutrality is free right now, and will not stay free.

### What breaks

**1. Memory lives inside the target repo.** `.claude/memory/<branch>/`.

```
two targets        → two memory dirs, no shared ledger
read-only target   → nowhere to write
same branch twice  → two attempts collide
```

`.gitignore` already ignores `.claude/memory/` because memory is per-developer, not per-repo. The
design has not caught up to its own gitignore.

**2. `panel.yml` is a contract nothing reads.** Three prose mentions, zero readers.
`plugins/panel/agents/author.md:54` tells a *model* to run "whatever `panel.yml` declares".
`craft-oracle` forbids that shape on line one.

**3. Panel's Law 5 is off where Panel is used.** Law 5 says verdicts are committed artifacts.
`.gitignore:5` excludes `.claude/panel/`.

**4. A gate's meaning is mutable by the thing it grades.** `craft-oracle:15-16` says to prefer the
project's own script — `composer test`. The worker edits that project. **Approving the text
`composer test` approves an indirection whose meaning the worker controls.** This is the deepest
break, it was invisible in revisions 1 and 2, and it is what §2.2 now exists to close.

**5. Failure learning has three ledgers and no path between them.** `working.md` Failures (session,
pruned), `observations/` (permanent, manual), verdicts and promotion (per repo, counted by a model).

### If we do nothing

Every capability being asked for — replaceable sources, multi-repo work, isolated workspaces, safe
parallel work, a developer joining a live session — is a property of a chain of execution nouns that
Foundry has never named. Kernel says branch, Panel says charter, the template says blueprint.

---

## 1. The chosen vocabulary

Three groups. Every word earns its place by carrying something the others do not.

### Structure

| Word | Means |
|---|---|
| `contract` | a shape something must satisfy — a file layout, or a command's exit code |
| `adapter` | something that satisfies a contract |
| `seam` | a place an adapter will plug in, whose contract is deliberately not written yet |
| `plugin` | how adapters and skills are packaged and installed |
| `skill` | how to perform a reusable procedure |

`seam` is new in revision 3. Revision 2 called workspace and delivery "adapters" while defining no
contracts for them, which broke its own definition of the word. A seam is honest about the gap;
calling it an adapter was not. See §2.6.

### Execution — the chain, with cardinality

Cardinality is the proof these are distinct. Collapse any two and a real case breaks.

| Word | Means | Count | Breaks if collapsed |
|---|---|---|---|
| `work item` | what someone wants | 1 | — |
| `run` | one attempt at a work item, **planning included** | N per item, over time | planning output has no ledger |
| `unit` | a bounded piece of a run, carrying a **brief** | N per run | parallel pieces share a workspace |
| `workspace` | isolation in which commands execute | 1 per unit, plus 1 read-only for planning | two units corrupt each other |
| `target` | a repo and ref a unit may change. **At most one** is the bootstrap target — §2.3 | N per workspace | one item cannot span repos |
| `session` | an agent conversation attached to a workspace | N per workspace, over time | a crashed agent loses the work |

A unit's **brief** is bounded input, one responsibility, useful output — `ground-delegation`'s
existing briefing shape. It is deliberately not called a contract: `contract` is reserved for the
five shapes in §2, and revision 2 used the word for both, leaving "a unit has its own contract"
undefined.

```
work item ──┬─ run (attempt 1, abandoned during planning)
            └─ run (attempt 2)
                 ├─ planning ────── workspace (read-only)
                 ├─ unit: backend ─ workspace ──┬─ target acme/api @ main
                 │                              └─ session (agent, then human)
                 └─ unit: frontend  workspace ─── target acme/web @ main
```

### Decision inputs — who enforces

| Word | Means | Enforced by | Overridable from inside a run |
|---|---|---|---|
| `context` | what a model may read | nothing | n/a — a model may ignore it |
| `policy` | what code refuses | code | **no** |
| `evidence` | a stamped record carrying a trust level | provenance | no — there is no write API |

### What was cut, and why

| Cut | Absorbed by | Reason |
|---|---|---|
| `capability` | `contract` | Two nouns, one idea. A contract states *what shape*; a capability states only *that something is possible*. A slot invites a registry |
| `rule` | `context` | Constraints a model reads and nothing enforces are context. The substance survives as a convention: repo-native instruction files are discovered, not configured — §3 |

---

## 2. The portable contracts

Five. Each is a **shape**, not a file. §4 records which serialisation v1 uses.

### 2.1 Work source

Revision 2 defined a passive five-field item and called it the contract. That left **no channel for
asking a human anything** — which §2.2 and the `Decided:` clause both require. A work source that
cannot report back is a fetch.

Four operations. The item shape is the first of them, not the whole contract.

| Operation | Shape |
|---|---|
| `read` | items — `{ id, source, title, body, targets[] }` |
| `publish` | run state, addressed to the item |
| `ask` | a question addressed to a human — the decision, the evidence behind it, the options with what each one causes, and a recommendation where one is defensible |
| `receive` | an attributed human answer, bound to the run and the question it answers |

**`ask` and `receive` are why this matters.** A human is asked *where they already are* — the issue,
the ticket, the channel — not in a terminal nobody is watching. That is the difference between human
authority and human interruption, and it is a property of the transport, not of a policy.

**`receive` carries an answer. It does not decide what the answer means.** An earlier draft said it
returned evidence at trust `human`, which made the transport the author of a semantic claim it cannot
make: an authorisation answer and a satisfaction answer arrive through the same channel and mean
entirely different things. Who reads it decides:

| Read by | The answer means |
|---|---|
| authorisation | this clause may exist — **authority, scoped to this run and this clause, saying nothing about whether it was met** |
| completion | for a `Decided:` clause, that the clause was met — `human` evidence, as §2.5 defines it |

**Both name a clause, and the stage is what keeps the two questions apart.** An introduced clause is
authorised by one question and, if it is `Decided:`, satisfied by another about the same clause in the
same run. Naming cannot separate those; who asked can:

```
question = run + stage + clause
```

**`stage` is the reader, not the moment.** §2.2 re-derives the charter and re-evaluates its conditions
*at* completion, so a lifecycle clock would stamp both questions the same and collide them. What the
term names is which stage asked, and therefore which stage may consume the answer.

**Completion never reads an authorisation answer, because it never asked that question.** Drop the
stage and the two collapse: the answer authorising a clause's existence would satisfy it, which is
the defect revision 9 closed for entailment verdicts. It returns for human answers unless the stage
is carried.

**Three terms, and the fourth was tried.** Revision 12 first keyed the condition that fired as well.
It never discriminates: for one clause at authorisation, either the judge said no — or none could be
formed — or the judge could not tell. Never both, because §2.2 makes them disjoint, and the question
is *may this clause exist* either way. The condition is what the ask must **say**, so a human knows
why they are being asked. It is not what the answer must **match**.

**Authorisation transports conditions one and two, and nothing else.** Three refuses and four
refuses — §2.2 says why. Completion transports its own question, for `Decided:` clauses, which is the
requirement this section opened by naming.

**That identity is derived rather than issued.** Every term already exists when the question is asked,
and a resumed run recovers all three from what it already holds — the run from where it is, the stage
from which one is asking, the clause from the charter. None of them is the base: an introduced clause
has no base to recompute from, and that is the clause conditions one and two ask about. So a resumed
run finds its own question rather than asking a second one, an answer to another question does not
match, and an answer to an earlier run does not either. Issuing an identity instead would mean storing
it, and a stored pending question is the parallel ledger §2.2 refuses.

**A stable identity is not a stable question, and only one of those is free.** Whether a clause is
asked about at all turns on a judge, and re-convening a judge on resume can answer differently — so a
question a human is already holding can stop existing, with its identity still perfectly derivable.
That is why §2.2 records what the judge answered and a resumed run replays it. The record is a
provenance judgement, not a pending question: nothing reads it to find an outstanding ask.

A clause's identity is its text, so editing a clause asks a new question. That is correct: a changed
requirement is a different requirement, and the old answer authorised the old one.

Anything that can do these four is a work source: GitHub Issues, Linear, a directory of markdown
files, a CLI argument, another agent. A source that can only `read` is usable and says so; it forces
every `ask` to block.

**A work source is not a target.** `publish`, `ask` and `receive` write *to the source* — comments,
status, questions. None of that makes the source repository writable as code. A work item arriving
from `acme/issues` grants no authority to change `acme/issues`. See §2.3.

### 2.2 Charter — the definition of good

**Good is not the gate list, and it is not a form a human signs every time.**

A charter is a set of clauses. Each is machine, judged or human:

```markdown
## Done when
- [ ] Gate:    tests                              machine   ← acme/api@main, gates
- [ ] Gate:    types                              machine   ← acme/api@main, gates
- [ ] Judged:  adversary approves, risks recorded judged    ← acme/api@main, CLAUDE.md
- [ ] Decided: pricing copy signed off            human     ← introduced by planning
```

**A `Gate:` clause names a gate. It does not carry a command.** §2.4 resolves the name per target;
the gates stage runs it. Revision 5 wrote the command here, leaving one fact in two places and
making invariant 2 unanswerable — pinning a command means pinning whatever it resolves through.

#### The four invariants

These replace routine approval. Each is checkable by code, not by the worker's assurance.

| # | Invariant | What it means |
|---|---|---|
| 1 | **Provenance** | Every clause names the human-owned artifact it came from — a repo script or an instruction file — **and establishes the link by one of exactly two paths, mechanical or semantic (below).** A clause that establishes neither is *introduced* |
| 2 | **Pinning** | That artifact is captured at the base ref of **the target it came from** — §2.3's `ref`. Both the clause *and its resolution* are pinned |
| 3 | **Monotonicity** | The set of requirements may grow. It may never shrink. A clause's kind is not a rank on that set — below. **The baseline is what the pinned artifacts derive now, never a previous run's charter** |
| 4 | **Authority** | Selecting the work item **is** the human act, stamped as run-scoped `human` **authority** — never evidence, because it names no clause and so answers nothing about one. It authorises everything derived from artifacts that human already owns |

#### The kinds are not a scale

`Gate:`, `Judged:` and `Decided:` say how a clause's truth is established. They do not rank it.

Turning `Judged: the interface is understandable` into `Gate:` strengthens nothing. It demands a
command that does not exist, and inventing one produces the green gate that certifies nothing —
`craft-oracle`'s first failure. `Decided:` is not the weakest either. It carries authority no
command can hold.

So monotonicity is about the requirement, and never about the kind:

```
add a clause      the set grew         allowed
remove a clause   the set shrank       refused
change the text   a different requirement, so the old one is being removed
change the kind   only derivation, and only by establishing provenance
```

**A human may not change a kind.** Deciding that a requirement is now established differently is new
meaning, and new meaning goes into a human-owned artifact where derivation finds it. Editing the
charter to say so skips the artifact and leaves the claim pinned to nothing.

This also settles what happens when something introduced is later derived. Provenance arriving is
not promotion — the clause was introduced because nothing established it, and now something does.
Derivation says so by setting the kind. Nothing else may.

#### The baseline is derived, not inherited

A previous run's charter is history, not authority.

Two cases decide it. A human who relaxes a requirement edits a human-owned artifact and commits it —
the next run's base carries the change, and the lower bar is correct. A charter from a buggy
derivation would otherwise become law; re-deriving is the only thing that clears it.

Three confirm it. The first run has nothing to inherit. Two runs from one base derive the same
baseline without finding each other — and `run` is N per item, so "the previous charter" names no
single document. A failed run binds nothing.

**`Decided:` clauses therefore do not carry forward.** A decision meant to last belongs in a
committed artifact, not in one attempt's ledger.

#### Pinning closes break 4

`Gate: tests` is an indirection. Something resolves the name to a command, and that is what a worker
would move.

Revision 5 pinned "every file the gate resolves through" and listed `composer.json`, `package.json`,
CI config. That set is open — a gate may `curl | sh` — and §7's second question marked it blocking.
It also forced a choice with no good side: pinning `composer.json` whole downgrades every gate on a
dependency bump; pinning one key inside it needs a JSON parser, which §4 forbids.

**The set is not open, because Foundry authors the detector.** Resolution is Level 1 detection —
Foundry's own code, reading files it chose. So pin what it read and what it answered:

```
at base       the files the detector read, at their base shas, and the command it resolved
at delivery   run it again — the answer moved, or a file it read moved  →  downgrade
```

> **If the resolved command differs between the base and delivered refs, or any file the detector
> read differs, that clause's evidence is downgraded from `machine` to `judged`.**

Foundry never reads `composer.json` for meaning. It records what it read and whether its own answer
changed. Level 2 covers detection being wrong.

Downgraded, not voided. Legitimate work changes test scripts — adding a suite is good. Voiding would
punish it. Downgrading says the exit code no longer speaks for itself and something that is not the
author must look. One `git diff`, no machinery.

**The residual.** A worker can leave the command intact and change what it reaches — `phpunit.xml`,
a bootstrap, an environment file. That is the workspace boundary's to close, and why this is
correctness rather than containment.

#### Pinned is not governed

§2.3 separates *authorised* from *selected*. Provenance needs the same separation from coverage.

A **pin** records where a clause's meaning came from. It never records what the clause is answerable
for. A clause derived from `acme/tools` may be answerable for `acme/api` and for nothing in
`acme/tools`.

**In v1 every clause governs every selected target**, with one derived exception: a `Gate:` clause
governs each selected target that **declares that gate** (§2.4), read from that target's own pinned
declaration. Nothing else states coverage.

**A target whose declarations cannot be read stays governed.** Today that is every target but the
bootstrap, because detection reads one checkout — so an unevaluable exception must widen nothing and
narrow nothing. Wrong toward *governed* is the safe direction; the alternative is a bar that quietly
stopped applying.

**Name its cost, because it is not the downgrade's.** A downgraded gate routes to a judge who can
answer. A `Gate:` clause governing a target whose gates cannot be read has **no `machine` producer,
and no downgrade to route it to a judge** — §2.4 runs a gate only where it is declared, and the
downgrade compares a resolved command at two refs, which needs the declaration readable at both. So
the clause cannot be evidenced there, and §2.5 blocks delivery with nothing able to unblock it.
A `Judged:` or `Decided:` clause pays no part of **this** cost: neither producer needs a gate
declaration. That does not make it deliverable. §2.5 stamps evidence at each selected target's
delivered ref, and with no checkout there is no second delivered ref to stamp — so **multi-target
completion waits on the workspace seam whatever the charter holds**, which is why §8's experiment 2
records a two-target run failing today. v1 ships one unit against the bootstrap target, where the question does not
arise. §8 tests the `Gate:` half.

**A clause that governs no selected target is refused, not evidenced.** A charter whose clauses grade
nothing is not a low bar; it is not a bar. §4 says when that refusal binds.

Narrowing coverage below this is deliberately absent. It is a weakening, and v1 can derive no
narrower answer from a pinned human-owned artifact — so there is no honest way to record who
authorised it, and a coverage dial nobody authorised is worse than none. It becomes expressible when
per-target declarations are readable.

**The honest limit**, in the terms this section uses for the charter and §2.5 uses for evidence:
coverage is a function of `units/NN/targets`, a file the worker can write as the same user. Policy
guards the act of adding a target, not the file's contents when they are next read — so a
hand-appended line widens what every clause grades, and a hand-deleted one removes a delivery
precondition without removing a clause. Re-derivation cannot catch it either: the charter is
unchanged, and it is the selection that moved.

#### Two derivation paths

Mechanical truth is code's. Semantic entailment is a judge's. New meaning is the human's.

| Path | Question | Answered by | Clause trust |
|---|---|---|---|
| **mechanical** | Does the artifact *yield* this clause? | code | `machine` |
| **semantic** | Is this clause *entailed* by the artifact? | an independent judge | `judged` |
| — | Neither holds | the human | `human` |

```
clause candidate
    │
    ├── code derives it from a pinned artifact?          → mechanical provenance
    │      the target declares a gate named `tests`
    │      therefore Gate: tests
    │
    ├── else — an independent judge finds it entailed
    │          by a pinned human-owned artifact?         → semantic provenance
    │      CLAUDE.md: "every public API change ships a deprecation"
    │      therefore Gate: the deprecation check
    │
    └── else                                             → the human
```

**Semantic is a fallback, never a parallel default.** It is attempted only where mechanical
derivation cannot reach — otherwise the cheaper, stronger path would be skipped for the weaker one,
and the charter would become an LLM approval step with extra words.

Four constraints keep it from becoming exactly that:

| Constraint | Why |
|---|---|
| **Ordering** — only reached when code cannot derive | Keeps the judge off the common path |
| **Independence** — **fresh**, **read-only**, neither the proposer nor any agent that will implement the unit, unable to mutate the charter, and judging from the pinned artifact and the candidate clause alone | The worker may not certify its own provenance. Panel's Law 4 shape, `tools: Read, Glob, Grep` |
| **Entailment, not endorsement** — the judge answers *"is this clause entailed by artifact X at ref Y?"*, never *"is this a good clause?"* | A narrow question has a defensible negative. A broad one collapses into taste |
| **Three answers, not two** — entailed, not entailed, **ambiguous**. Ambiguous escalates | A judge forced to choose binary will guess, and guessing is how new meaning slips through |

**The judge's power is deliberately asymmetric.** It can *prevent a question* by confirming meaning
already existed. It can never *permit a weakening* — condition three below routes every weakening to
the human regardless of what any judge thinks. So a compromised or over-agreeable judge costs an
unnecessary question at worst; it can never lower the bar — **and the record it produces can never
certify that the clause it established was met, because an entailment verdict is not evidence.**
Without that second half the asymmetry does not hold: one record would create a clause and satisfy
it, and condition three, which is about removal, would never fire.

**That separates the records. Eligibility separates the agents** — *fresh* means a judgement is made
by an agent convened for it, so the judge that established a clause is not the one that later says
the work met it. Revision 9 could not claim this; revision 11 can, and only because eligibility is
now a rule rather than a convention.

**Every attempt at the semantic path is recorded** — the verdict, or that no eligible judge could be
formed. The record is one of its own, naming the clause, the artifact and its ref; `entailed`
additionally establishes the pin. **Not one of them says a clause was met**, and the one that
establishes anything says only that a requirement legitimately exists. Judgements stay countable,
which is what later lets a recurring one be promoted into a mechanical check — `craft-oracle`'s
promotion rule, unchanged.

**Revision 11 kept a verdict only beside the pin it established — the one answer that needed keeping
least.** *Not entailed*, *ambiguous* and *no eligible judge* establish no pin, and each of them fires
an authorisation condition that asks a human. So the fact that produced the question was the one fact
nothing kept. A run that stops with a question outstanding re-convenes a judge when it resumes, that
judge may answer differently, and the question the human is holding then derives differently or not at
all.

**A recorded verdict is replayed, not re-judged.** The judge was asked whether *this* clause is
entailed by *that* artifact at *that* ref; the verdict is about that triple, so replaying it answers
the identical question. A second convening that answered differently would be the judge being
non-deterministic, not new information. A changed triple — an edited clause, a different pinned ref —
is a different question and gets a fresh judge. A new run gets one for every clause.

**The no-judge record replays for a different reason**, because no judge was asked and there is no
consistency to hold anything to. What is fixed is the run's *attempt*. Eligibility is a property of
which agents exist, not of the triple — so a judge becoming available mid-run would change the charter
by availability alone, and strand the question already asked. The run keeps the attempt it made; a new
run makes a new one.

**The record is written before the ask goes out**, and that ordering is the whole of what it buys. A
run that stops between judging and asking resumes with the verdict already fixed, so it asks the same
question it was about to ask. Written after, a stop in that window re-convenes the judge and the
defect above returns unchanged.

**That is a record of what a judge answered, never of what is awaited**, and the lookup direction is
what says so. A resumed run derives its own question and finds the verdict recorded *for that clause*;
nothing anywhere asks *which questions are outstanding* and gets an answer. Nothing clears it either,
and it cannot say a clause was met. A pending-question ledger would be all three of those things.

**This is Panel verifying, not Panel planning.** The judge is handed a candidate clause and asked
whether meaning already exists. It proposes nothing.

#### The authorisation gate

Four conditions fire on a clause or on a target. The first two ask a human; the last two refuse:

```
no provenance — the judge said no, or none could be formed   ask     new meaning was introduced
no provenance — the judge could not tell                     ask     the meaning is genuinely unclear
a clause the pins still derive is gone                       refuse  invariant 3 was violated
a target is outside the allowlist                            refuse  policy refuses (§2.3)
```

None of the four fires → **no human is asked, and the run proceeds**, unless the charter does not yet
describe work at all — below. That is issue #66's convention test satisfied: *mark/select work → work
runs*.

**For a repository the detector reads a gate from.** Level-1 detection reads three things (§2.4), and
a repository holding none of them derives an empty charter, which the refusal below ends. Foundry's
own repository is one: it declares its gates in a README and a workflow, and the detector reads
neither. So *work runs* is a promise about detection's reach, not about every repository — and
widening that reach is Level 2's job, which is why `.foundry/gates` exists.

The worker cannot dodge the gate, because none of the four conditions is reported by the worker. It
cannot lower its own bar, because lowering *is* condition three.

**Authorisation also refuses, and a refusal is not a fifth condition.** A condition fires on where a
clause's meaning came from, on a clause's removal, or on whether policy permits a target — invariants
1 and 3, and §2.3. **One and two ask; three and four refuse** — three because the remedy is a commit,
four because it is a separate human command. Two further cases stop the run without any of those
firing, because what is offered is not a bar at all:

| Refused | Because | Cleared by |
|---|---|---|
| the charter holds no clause | nothing is described, so there is nothing to authorise | a target declaring a gate, or a pinned instruction file carrying a requirement |
| a clause governs no selected target | a bar that grades nothing is no bar | declaring the gate that clause names, or a later run selecting a target it governs |

**The refused run ends. It does not re-plan.** Invariant 3's baseline is what the pinned artifacts
derive *now*, so an attempt from the same base and the same selection derives the same charter and
refuses identically. Every remedy above changes an input. Conditions one and two route to a person for
an answer; every other stop routes to an edit or a command — the artifact, the selection, or `policy`.

That holds for everything code derives. **A judge is the one input the base does not fix**, and the
verdict record above fixes it only within a run — so a fresh attempt may reach a different charter
without any artifact changing. Deliberate: a verdict carried between runs would be a run inheriting
provenance it never established, and invariant 3 re-derives *now* precisely to stop that.

**An authorisation answer authorises a requirement's existence. It never says the work met it.** A
`Decided:` clause reaches completion through the same channel and a **different** answer, which
completion reads as evidence. Both name a clause, so the stage separates the questions — §2.1 — and
§2.5 keeps the records in different stores. Without both, they arrive as `human` records naming a
clause and §2.5's completion invariant is back to guessing which one it is holding.

**Condition three asks nobody anything.** It fires when the pins still derive a clause the charter no
longer holds, and the model already says what a human does about that: *a human who relaxes a
requirement edits a human-owned artifact and commits it*. The remedy is that edit. There is no
question to transport and no answer to interpret — the run refuses, and the next run from the amended
base derives the lower bar legitimately.

So **only conditions one and two are ever transported as questions.** Both concern a single clause,
which is what lets a question be named exactly — below. Condition four is a policy refusal whose
remedy is a separate human command, and condition three is a refusal whose remedy is a commit.

Revision 11 decided that if condition three ever *did* carry an answer, that answer would name the
clause whose removal it authorises, one clause at a time. That constraint stands and binds nothing
today, because there is no such answer.

**Revision 11 also kept the evidence pool unambiguous by a naming rule — never name a clause the
charter still holds — and revision 12 retires it.** The rule cannot survive conditions one and two
being asked per clause: an introduced clause *is* in the charter, so its authorisation answer names a
clause the charter holds, and the rule forbids exactly what the model does. **The stage does that job
instead**, for every clause rather than only the ones being removed.

**An answer binds one run, and the ask must say so.** Invariant 3 re-derives the baseline from the
pins every time, and `Decided:` clauses do not carry forward — so the same base proposes the same
clause and asks the same question on the next run, for ever. Nothing in the model stops that, and
nothing should: a run cannot write permanent meaning. **What ends it is amending the pinned artifact,
and that is an option the ask names** — answer for this run, or change the artifact so no run asks
again. A question re-asked after it was settled is not new meaning, and this document's whole claim
is that a human is interrupted only where new meaning appears.

**When the conditions are evaluated decides whether that is true.** Derived once at planning and
trusted after, an in-flight edit of the charter is silent. So the charter is re-derived from its
pins at completion and compared with what it holds.

**A condition firing there does exactly what it does at planning** — one and two ask, three and four
refuse. Nothing about the stage changes; a clause introduced mid-flight still needs a human, and a
clause deleted mid-flight is still condition three. The question is an *authorisation* question
whenever it is asked, which is why §2.1's `stage` names the reader and not the moment: at completion,
a lifecycle clock would stamp it the same as the satisfaction question and collide the two.

**The honest limit**, which §2.5 states for evidence and floor's README for policy: the charter is a
file the worker can write, as the same user. Re-derivation catches accident and drift, not a worker
editing charter, pins and verdicts together — a forged `entailed` buys exactly one thing, the silence
where a human would have been asked. That is the workspace boundary's, and it does not exist yet.

#### Where this sits relative to Panel

Panel's per-run human approval (`craft-charter`) is load-bearing **inside Panel's scope** —
deliberately convened, high-criticality, low-reversibility work, which its own README says is rare.
Universalising it to every run was revision 2's error and it contradicted the issue directly.

The charter contract lives in the new plugin, not in Panel. Panel declares a kill criterion it has
never run; if Panel is deleted, the definition of good must survive.

`craft-oracle`'s Coverage Rule still holds: if no clause can be a `Gate:`, that is a finding about
the work.

### 2.3 Targets

```
repo    an identity — a clone URL or a source-relative name
ref     a branch, tag or sha
```

**A target declaration never contains a local path.** The path is workspace-local state, not part of
any contract.

**Two levels, and they are not equal:**

| Level | Authority |
|---|---|
| work-item targets | **advisory.** They arrive from outside and may be attacker-controlled |
| unit targets | **authoritative**, produced by planning, filtered by policy |

That gap is the first real `policy`. A work item is written by whoever can file one. Without a
filter, a hostile item naming `attacker/repo` is a push. **The target allowlist is not speculative
and open question 2 is closed: `policy` stays, and the allowlist is its first instance.**

#### The bootstrap target

> **bootstrap target** — the target repository or workspace Foundry was invoked from.

**Zero or one per run.** Invoking Foundry inside a repository is the human act that makes that
repository a target. Starting from a central work source, a bare CLI call, or a remote runner is
equally valid and produces none — and forcing one would mean writing a local-path identity, which
this section forbids two paragraphs down.

```
default target allowlist = the bootstrap target, when one exists
                         + explicitly human-authorised targets
```

A run with no bootstrap target starts with an empty allowlist. That is stronger, not weaker: every
proposed target then fires the authorisation gate, which is correct, because no human act of
invoking-inside-a-repository ever happened.

#### Authorised is not selected

**Being on the allowlist permits a target. Putting it in `units/NN/targets` chooses it.** Two
different acts, and the bootstrap target does not cross between them on its own.

| | |
|---|---|
| **authorised** | policy will not refuse it — §2.3's allowlist |
| **selected** | planning wrote it into a unit's targets, so work will touch it |

The error this blocks runs both ways: seeding a unit's targets from the bootstrap target would turn
*where Foundry was started* into *what the work may change*, silently; and reading a target's
presence in `units/NN/targets` as authorisation would let a hostile work item select a repo policy
never permitted.

**Planning normally selects the bootstrap target in the zero-configuration case**, and should — that
is what makes *mark work → work runs* true for the commonest invocation. It is a planning step with a
default, not an identity between the two sets.

Revision 3 said "the run's own origin", which is ambiguous in a model that separates source from
target: a run has both, and only one of them is writable.

**A work-source repository does not become a writable target because the work item came from it.**
Items filed in `acme/issues` grant no authority over `acme/issues`. If a team genuinely wants that
repo writable, it is authorised like any other target — by a human, explicitly. Under §2.3's
run-scoped allowlist that is once **per run**; the durable grant scoped to a source is the work-source
stage's, and §9 orders it there.

The bootstrap target is the only entry on the allowlist that needs no human act, because invoking
Foundry there *was* the human act. Everything else is authorised or refused.

```
work source   acme/issues        ← where the work is described
targets       acme/backend       ← where the work happens
              acme/frontend
              acme/mobile
```

### 2.4 Gates

One gate per line: first field is the name, the rest is the command.

```
tests       composer test
types       vendor/bin/phpstan analyse
```

Whitespace-separated, so there are no invisible tabs to lose. `#` comments, blank lines ignored.
`awk` reads it in one line: `{ name = $1; $1 = ""; cmd = $0 }`.

**Gates are declared per target and run with that target's checkout as the working directory.** A
workspace holds N checkouts; `composer test` in a two-repo workspace is otherwise ambiguous.
Revision 2 dropped `panel.yml`'s `workdir` column and made workspaces multi-target in the same pass,
which made the ambiguity worse rather than better. Per-target declaration removes the column instead
of restoring it — each repo already knows its own gates.

### 2.5 Evidence

Append-only records, each carrying a **trust level** naming who produced it.

```
at        timestamp
trust     machine | judged | human
unit      which piece of the run
name      the gate, judge or decision
result    exit code, verdict, or answer
ref       the sha it applies to
why       on failure, what the command said
```

| Trust | Produced by | Forgeable in v1 |
|---|---|---|
| `machine` | a command's exit code, recorded by the runner | not through the API. Yes, by writing the file directly |
| `judged` | an agent that cannot write what it judges | an attributed opinion; forgery means impersonation |
| `human` | completion, reading the answer to the question it asked | yes — the gap Panel's charter already names |

`judged` evidence has one producer: an independent judge answering whether a clause was **met** — a
review **verdict** at completion for a `Judged:` clause, or the second look a downgraded `Gate:`
clause requires. **No record of a semantic attempt is evidence** — entailed, not entailed, could not
tell, or no judge to ask. Each answers whether a clause legitimately exists, which is provenance, and
§2.2 records them with the charter's pins. Both kinds are attributed and both are countable, which is
what lets a recurring judgement be promoted into a mechanical check later.

**`human` evidence has one producer too, and it is not the transport.** An answer reaches the run
through the work source's `receive`, which carries it and decides nothing about it — §2.1. Completion
makes it evidence, by reading the answer to a question completion asked about a `Decided:` clause it
holds.

**Not every `human` record is evidence, and prose is not what keeps them apart.** Selecting the work
item is stamped `human` — invariant 4 — and so is an authorisation answer. Neither answers *was this
clause met*, but an authorisation answer names a clause, and the shape above cannot tell the two
apart: `name` holds the clause either way, and the stage lives on the question, not on the record.

**So they are not in this ledger**, on the principle revision 9 already used: remove the record from
the pool rather than add a field to sort it. Their own shape, and it is not this one:

```
at        timestamp
who       the person, attributed
what      the run, or one clause
```

No `unit`, no `ref`. Selection has neither — §4 stamps it before the run exists — and an authorisation
answer authorises a clause's existence, which no ref makes truer. **A record without a `ref` cannot
satisfy the completion invariant**, which quantifies over the delivered ref of every selected target.
That is the separation, in the shape rather than in a sentence about it.

**The stage and the store do different jobs, and neither does the other's.** The stage separates the
*questions*, so an answer reaches the reader that asked it. The store separates the *records*, so a
reader never holds one meant for the other. Drop either and §2.5's completion invariant is back to
guessing.

**Machine evidence cannot be faked through the API, because there is no API for it.** The recorder
takes a command, runs it, and stamps what happened. There is no parameter for a result:

```sh
record() {                       # name, command
    run "$2"; status=$?
    stamp machine "$1" "$status"
    return $status
}
```

Same move Panel makes with `tools: Read, Glob, Grep` — remove the capability rather than forbid its
use. A model may still append by hand. **That gap is not closed in v1**, stated in the same terms
Panel's README uses for Law 1.

#### The completion invariant

Nothing in revision 2 said when a run was finished. Gates could pass at commit N, three commits
land, and delivery proceed on evidence that no longer applied.

> **A run may deliver only when the charter holds at least one clause, at least one target is
> selected, and every charter clause has satisfying evidence stamped at the delivered ref of every
> selected target it governs.**

**An evidence record that names a charter clause answers one question: was that clause met.** A
record answering anything else about a clause — above all whether it legitimately exists — is not
evidence. *Satisfying* evidence is such a record whose answer is yes.

**The first two conjuncts close fail-opens, not edge cases.** The invariant quantifies over clauses
and over targets, so an empty charter and an empty selection each satisfy it vacuously. Every fresh
run has the second; any repo the detector reads no gate from produces the first.

**Per target, because there is no run-level ref.** A clause spanning two targets is satisfied
against `acme/api@sha1` *and* `acme/web@sha2`; "the delivered ref" names neither. Revision 5 fixed
this on the base side and left the delivered side singular.

Panel already had this — `craft-verdict:67` stamps `branch @ sha`. Revision 2 dropped it. This is
also why `Decided:` clauses need no second gate: they are clauses, so completion waits for them.
One invariant, two jobs.

### 2.6 Named seams, contracts deferred

Revision 2 said delivery "needs no shape of its own." That denied a contract rather than deferring
one, while §3 promised adapters could be swapped without touching neighbours — which is impossible
when an adapter's interface is unstated.

These are **seams**. Their contracts are deliberately unwritten, and until written they are unproven
under the two-adapter rule.

| Seam | What plugs in | Starting sketch |
|---|---|---|
| `workspace` | worktree, container, VM, cloud sandbox | create · run commands · expose a service · keep or publish a branch · destroy |
| `delivery` | branch and PR, patch, direct push | publish an outcome, stamp evidence |
| `browser` | Playwright, and its peers | named in issue #66; no sketch yet |
| `session` | provider-specific attach | no sketch; see §4 |
| `agent` | Claude Code, and its peers | orchestrated, never wrapped — §3 |

The workspace sketch is the synthesis's, kept because it is a better starting point than nothing.
It is a sketch, not a ratified contract.

---

## 3. Conventions and escape hatches

### Level 1 — zero configuration

| Question | Convention | Derived from |
|---|---|---|
| Where runs live | a Foundry home outside every target | — |
| Which run is active | asked of the workspace adapter | §4 |
| What the work source is | GitHub, when the remote is GitHub and `gh` is present | the repo |
| What the targets are | planning selects the **bootstrap target**, when there is one | the repo |
| What the gates are | detected — `composer test`, `pnpm test`, `make test` | each target |
| What context applies | **repo-native instruction files** — `CLAUDE.md`, `AGENTS.md`, neighbours | the repo |
| What the workspace is | an isolated checkout | the workspace seam |
| What delivery is | branch plus pull request | the delivery seam |
| What the allowlist is | the bootstrap target when one exists, plus targets a human authorised explicitly | policy |

Repo-native instruction discovery is why `rule` did not need to be a noun, and it is what makes most
charter clauses derivable under invariant 1.

### Level 2 — small overrides

A repo declares only what differs. Gates when detection is wrong. A source repository when work
lives elsewhere. An allowlist when a run legitimately spans repos.

### Level 3 — full composition

Replace an adapter without touching its neighbours. This is what the contracts buy, and it is why
§2.6 exists — a seam with no contract cannot honestly make this promise yet.

### Defaults must explain themselves

One command prints every default and the reason for it. `signal`'s preflight is the precedent —
silent when it works, one line when it cannot answer.

### Provider neutrality without lowest-common-denominator design

> **A contract may not name a provider.**
> **An adapter may not be required to hide one.**

Foundry **orchestrates** a provider; it does not wrap it. Credentials, model selection and
provider-specific features stay with the provider. Neutrality is bought by keeping contracts as
shapes and exit codes — not by writing interface types with one implementation.

### The two-adapter rule

**A contract is unproven until two adapters satisfy it.** In v1 only the work-source contract meets
that bar, and it must — a single GitHub adapter is a GitHub model wearing a costume. Every seam in
§2.6 is unproven and marked so.

Falsifiable form: **a directory of markdown files must work as a work source in under twenty lines**
for `read`, and must be able to `ask` by writing a file and `receive` by reading one.

---

## 4. Run lifecycle, and what stays implementation-specific

### The lifecycle

Revision 2 contradicted itself: §2.2 said the charter was approved "before a run starts", while §5
said planning *produces* the run's contents. Planning therefore had no ledger — recreating the
three-ledger disease this RFC diagnoses in its own Problem section.

```
work item selected              ← the human act. Stamped as `human` authority, not evidence
    │
    ▼
run created                     ← the ledger exists. Nothing has mutated
    │
    ▼
planning                        ← read-only workspace
    │                             reads targets, repo context, policy
    ├──▶ charter   clauses, each with provenance
    ├──▶ units     each with a brief
    └──▶ targets   authoritative, filtered by the allowlist
    │
    ▼
authorisation                   ← §2.2's four conditions. Two ask, two refuse
    │                             otherwise silent, and the run continues
    │                             refuses a charter with no clause, or a clause
    │                             governing no selected target — §2.2
    │                             the selected set freezes here, and coverage with it
    ▼
mutating execution              ← one workspace per unit; gates run; evidence accumulates
    │
    ▼
completion                      ← every clause evidenced at the delivered ref of every
    │                             selected target it governs (§2.5)
    ▼
delivery
```

**Creating a run is not authorising mutation.** That separation is the point, and it is what lets a
run be abandoned during planning at no cost — already implied by run-per-attempt cardinality.

**The selected target set freezes at authorisation, and coverage freezes with it.** §2.2 derives
coverage from selection, so the two cannot bind at different moments. That is also where §2.2's
refusal lands — a clause governing no selected target is refused *there*, not while planning is still
writing `units/NN/targets`, where every clause governs nothing yet and refusing would refuse the
whole charter. That refusal is not one of §2.2's four: nothing fired about where the clause came from
or about its removal — it simply grades nothing, so it is no bar. Changing the selection afterwards
*would* trigger a condition: v1 has four, so a change after the freeze is a new run.

**Planning gets a read-only workspace, scoped to the run.** It must read the targets:
`decide-boundary`'s tells "surface only in code", and gate detection reads the repo. The alternative
— modelling planning as a unit — is circular, since planning is what produces units. The invariant
that matters either way: **planning's workspace cannot mutate a target.**

### Implementation-specific in v1

Named as adapters or seams so none of it becomes ontology.

| Concern | v1 choice | Status |
|---|---|---|
| Workspace | git worktree | **seam.** A container, VM or cloud sandbox is equally valid |
| "Which run am I in" | a pointer inside the git directory — never committed, per-worktree by construction | **adapter detail**, not the model's answer |
| Transport | files under a Foundry home | **v1 transport.** See below |
| Runtime | `sh` and `awk`, no `jq`, no `python` | repo constraint — `plugins/kernel/README.md` |
| Harness | Claude Code hooks and skills | the only harness that exists today |
| Work source | `gh` | first of two |
| Agent | Claude Code | one provider; the contracts do not name it |

### Filesystem: transport, not architecture

> **Every contract must survive being serialised and moved to another machine.**
> No absolute paths inside a contract. No reliance on producer and consumer sharing a disk.

Revision 1's `targets` file failed this outright. The rule is worth more than the fix — it is what
catches the next such error.

### Sessions and developer takeover

`session` is named with its cardinality; **v1 ships no session machinery.** Attaching to a live agent
conversation depends on provider support that is not generally available.

One thing works in v1 with zero code: because the workspace holds the checkouts and the run holds the
ledger, **a person can join by opening a shell in the workspace and reading the run.** That is the
test of whether the decomposition was right — if joining required new machinery, the nouns were wrong.

### Units: named now, one shipped

v1 creates runs with exactly one unit. The layout accommodates N from the start. Naming it now costs
one directory level; adding it later moves every path in every adapter.

**This is not a graph.** A run has units; units may declare dependencies. Ordering N units is a
topological sort in ten lines, and v1 does not need even that.

---

## 5. Convergence with the synthesis

Revision 2 converged this RFC with an independently written synthesis. **That table claimed to record
"every material difference" and did not.** Five were missing, and their omission ran one way: toward
the RFC's positions. The completeness claim is withdrawn; the table below is what was actually
resolved, with the missing rows added.

| # | Disagreement | Resolution | Source |
|---|---|---|---|
| 1 | Unit and workspace separate from the run container | Adopted. The synthesis had no `run` noun; the separation is genuinely its contribution. Revision 2 framed this as a contest over `run`, which nobody had | synthesis |
| 2 | Cardinality of item / run / session / workspace / target | Six nouns with explicit counts, §1 | synthesis, extended |
| 3 | Containment: synthesis had unit → session → workspace; this RFC attaches sessions to workspaces | RFC. Sessions must be able to die and be replaced without losing the workspace. **Revision 2 made this inversion silently** — an unrecorded improvement is indistinguishable from an unnoticed one | RFC |
| 4 | `capability` vs `contract` | `contract`. Its substantive claim — the primitive is the contract, not the package — adopted | RFC |
| 5 | Should `rule` stay distinct | No. Folded into `context`; substance survives as repo-native instruction discovery | RFC |
| 6 | Filesystem: transport or architecture | Transport, plus a portability test revision 1's own file failed | synthesis |
| 7 | Evidence provenance and trust | Three trust levels, matching the charter's clause kinds | synthesis |
| 8 | Gates vs the wider definition of good | Good is the charter. Gates are its machine third | synthesis |
| 9 | **Human judgement vs human ceremony** | **Synthesis. Revision 2 resolved this by silence, in favour of the position that both issue #66 and the synthesis argue against.** §2.2 now derives what it can, has a judge establish what it cannot, and asks a human only where both fail | synthesis |
| 10 | **Work source bidirectional, or a passive item** | **Synthesis.** Revision 2 kept five read-only fields and left the human-input channel homeless — while depending on it. §2.1 restores `publish`, `ask`, `receive` | synthesis |
| 11 | **Workspace operations** | **Synthesis.** It carried a six-operation sketch; revision 2 replaced it with "no contract". §2.6 restores it as a sketch | synthesis |
| 12 | **Browser** | **Synthesis.** Named twice there, and in issue #66's attention list. Revision 2 lost it entirely. Now a named seam | synthesis |
| 13 | Provider neutrality | Two rules, no abstraction layer. Neutrality ≠ lowest common denominator | synthesis |
| 14 | Developer takeover | `session` named with cardinality; no machinery in v1 | synthesis, scoped |
| 15 | Two-adapter portability test | Generalised: a contract is unproven until two adapters satisfy it | RFC |
| 16 | Convention over configuration | The synthesis's three levels, with concrete Level-1 content | both |
| 17 | Source independent of targets | Both agreed. Only achieved once targets stopped carrying local paths | synthesis |

**Correction.** Revision 2 claimed neither document named delivery. The synthesis names it in its
Level-1 table. Delivery being a *separate slot from the source* is this RFC's contribution; naming
it was not.

**Deferred, not resolved.** The synthesis's *contracts first* — planning must find the work's
important touch points, its APIs, events, schemas and hand-offs — has no successor here. It is a
planning **method**, not a shape, so it belongs in a skill. `decide-boundary` fires: it activates
differently from everything in this RFC. Same for the seven-rule learning loop, whose rule 6,
*never let the proposer move the bar*, is invariant 3 restated.

### Ownership

A new plugin. Kernel's README states its own boundary: *"the thinking layer. It knows how to think,
not what to code."* A run is mechanism. Panel is the wrong home for a sharper reason — its README
declares a kill criterion never run, and orchestration must not rest on an unproven layer.

```
kernel   how to think        unchanged
panel    how to verify       gates and charter move out; judging stays
signal   how to speak        unchanged
floor    where work happens  new
```

### Compatibility

| Component | Change |
|---|---|
| `kernel` | `resolve-memory.sh` gains one rung above the branch. Byte-identical when no run is active. `CLAUDE_MEMORY_DIR` keeps its meaning — a *base*, branch appended (`resolve-memory.sh:9`, `tests/memory.sh:40`) — **and an active run outranks it entirely**, see below |

**An active run outranks `CLAUDE_MEMORY_DIR`.** Revision 4 said that variable "keeps its meaning" and
never said what happens when a run is also active. Implementing #67 forced the choice, and an
adversary caught that the RFC had ducked it: a user who relocated memory loses that setting silently
the moment a run exists.

Run wins, for one reason. `CLAUDE_MEMORY_DIR` is the base of the *branch* ladder — it answers "where
do branch-keyed memories live". A run is a different organising principle, not a different base, so
there is nothing for the base to modify. The cost is the silence, and the fix for the silence is
floor's announce hook rather than a precedence change.
| `panel` | `panel.yml` retired. The charter contract moves to `floor` so it survives Panel's kill criterion. Panel keeps judging and verdicts. **Its "Floor" term renames to "Bar"** — `craft-verdict:82`, `adversary.md:53` — which frees the word and makes Panel consistent with its own "lower its own bar" language. Two words; it rode with the kernel/signal sweep |
| `signal` | none |
| stack plugins | none |
| existing memory dirs | keep working, untouched, no migration |

---

## 6. Independent architecture consultation

Reviewed by a Claude Fable architect with no prior exposure to this work, given the repo, issue #66
read directly through `gh`, this RFC, and — in a second pass — the synthesis. It was not told the
author's preferred answers.

### The challenge that mattered

> A worker that rewrites `composer test` into a no-op passes an approved charter without touching it.

The RFC's headline property was not held by its mechanism. Human approval blessed stable text whose
resolution the worker controls, and `craft-oracle` actively encourages that indirection. Two full
revisions and an independent synthesis all missed it. §2.2's pinning invariant exists because of this
finding, and the Problem section now lists it as break 4.

### Accepted

| Finding | Effect |
|---|---|
| Clause resolution is unpinned | §2.2, invariant 2 — the deepest change in this revision |
| Lifecycle self-contradictory | §4 — run-first, planning inside the run |
| No completion invariant | §2.5 — deliver only when every clause is evidenced at each named target's delivered ref. **History**: revision 9 replaced *named* with *selected… governs* and added the two non-empty conjuncts |
| Adapter terminology broken | §1 and §2.6 — `seam` added; "delivery needs no shape" deleted |
| Per-run approval contradicts issue #66 | §2.2 — four narrow conditions replace ceremony |
| The allowlist is already necessary | §2.3 — open question 2 closed; `policy` stays |
| Work-item vs unit targets ambiguous | §2.3 — advisory vs authoritative |
| Gate working directory unspecified | §2.4 — gates declared per target |
| Browser missing | §2.6 |
| Charter must outlive Panel | §2.2, Compatibility |
| Work source is read-only and the ask-channel is homeless | §2.1 — the second-deepest change |
| `contract` used for two things | §1 — a unit carries a **brief** |
| §5 claimed a completeness it did not have | §5 — claim withdrawn, five rows added |
| `.gitignore` is line 5, not 6 | Problem, break 3 |

### Modified

| Recommendation | What was done instead | Why |
|---|---|---|
| A gate-file diff **voids or escalates** machine evidence | **Downgrades** `machine` to `judged`. Never voids | Legitimate work changes test scripts. Voiding punishes adding a suite. Downgrading says the exit code no longer speaks for itself |
| Two human gates — one before mutation, one for `Decided:` clauses | **One** authorisation gate. `Decided:` clauses gate *completion*, via the invariant already required by §2.5 | A second gate is a second concept. The completion invariant was needed anyway; reusing it is free |
| Planning as a by-convention read-only unit, **or** a run-scoped read-only workspace | The **run-scoped workspace** | Planning produces units. Making planning a unit is circular |

### Rejected

Nothing outright. Two things were noted and deliberately not acted on: the synthesis's *contracts
first* planning method and its learning loop are real substance, but `decide-boundary` says they
activate differently from everything here. They leave as separate work rather than being folded in.

### Also caught

`.claude/panel/charter.md` — cited by this RFC as precedent for refusing a speculative registry —
reads `## Approved: <pending — human>`. The RFC leaned on a charter that never passed its own gate.
Small, and exactly what this model exists to catch.

### Revision 4 — the narrow pass

Three points, no broader reopening.

**Semantic provenance.** Revision 3 made derivation purely mechanical, which was too strict: a clause
can be grounded in human intent that code cannot extract from prose. §2.2 now carries two paths, with
four constraints keeping the judge off the common path and one asymmetry — a judge may prevent a
question, never permit a weakening — that preserves the invariant revision 3 was protecting.

**Bootstrap target.** "The run's own origin" was ambiguous once source and target are separate nouns.
Replaced throughout by **bootstrap target**, with the rule stated where it can be missed: a
work-source repository does not become writable because an item came from it.

**The name: `floor`.** The factory floor — where work happens.

Against `ground-naming`:

| Test | `floor` |
|---|---|
| Specific over generic | A place of work. Not `core`, `engine`, `manager`, `runtime` |
| Does the name reveal the contents | Where runs execute. The contents follow from the place, as they do for `kernel` |
| Read the filename, know the contents | `floor/bin/run.sh` reads correctly |
| Family | kernel, panel, signal are each named for the thing at their centre. This plugin's centre is a *place* — runs, units, workspaces and evidence, ongoing and plural |
| Register | Two syllables, in the foundry metaphor, and it is what people already call this |

**`crucible` was considered and is one level too low.** A crucible is a vessel holding *one* melt —
that is a `run`, not the system that creates and governs runs. Naming the plugin after its central
noun would have been right if the central noun were singular; it is not.

Also considered: `bench` (only the workspace third), `forge` (near-synonym for the whole foundry —
naming a part after the whole), `run` (collides with Claude Code's built-in skill), `yard` and
`works` (generic).

**The one real objection, and its fix.** `floor` already appears in Foundry meaning the opposite
thing — a *threshold*:

```
craft-verdict:82   **Floor** — only oracles and Criticals force a round
adversary.md:53    the severity floor
```

That is a **bar**, and Panel already uses that word for the concept elsewhere. Panel's "floor" is the
weaker and less consistent use, so the collision is resolved by renaming Panel's term rather than by
avoiding the name — two words, and Panel reads better afterwards. `craft-sh:75`'s *"Bash is the
floor"* is ordinary English, not a term of art, and stands.

---

### Revision 5 — amended by implementation

Building the run and its targets falsified three statements. That is the process working, not the
RFC failing: an architecture that cannot be contradicted by the thing it describes was never load
bearing.

| Was | Is | What falsified it |
|---|---|---|
| §1: "Exactly one is the bootstrap target" | "At most one" | A run started from a work source, a bare CLI call, or a remote runner has none — and forcing one means writing a local-path identity, which §2.3 forbids |
| §2.2: pinned "at the run's base ref" | at the base ref of the target it came from | `ref` became per-target. With no bootstrap, the run-level ref had no referent for a whole class of runs |
| §9: fifteen predicted GitHub numbers | stages, no identifiers | Issues and PRs share one sequence. Within a day the numbers named pull requests, and the one that became an issue bound to a different stage |

**`authorised ≠ selected` is now explicit** in §2.3. It was implied three times and contradicted once,
by §1's own sentence — and the proof it prevents a real error is on the record: issue #70's first open
question asks exactly this, a careful implementer unable to resolve it from the RFC.

A narrow consultation confirmed all three and found the §2.2 pinning dependency, which nobody here
had noticed. It also warned that the stale numbers lived outside §9 — in the compatibility row, in
two "Blocks" notes, and in floor's own README. Swept.

Not changed: `0..1` weakens nothing. A run with no bootstrap target starts with an empty allowlist,
so every proposed target fires the authorisation gate — which is right, because no human act of
invoking-inside-a-repository ever happened.

### Revision 6 — amended before the charter stage

Building policy falsified one statement. Drafting the charter contract found four more, one of them
a disagreement between two sections of this document.

| Was | Is | What falsified it |
|---|---|---|
| §2.2: `Gate: composer test` | `Gate: tests`, resolved by §2.4 | §2.4 already defines a gate as `name command`, per target. The charter was copying the second field, so one fact lived in two places — and invariant 2 could not be answered, because pinning a command means pinning whatever it resolves through |
| §2.2 invariant 1: "a prior charter" is a provenance source | removed | It has no target and no ref, so invariant 2 cannot reach it. A source that cannot be pinned is not a source |
| §2.2 invariant 3: no baseline named | the pinned artifacts, never a previous charter | The two readings give different systems. A derivation bug would otherwise become law, and a human relaxing a rule in the open would be flagged as a weakening forever |
| §2.5: "stamped at the delivered ref" | at the delivered ref of every target the clause names | Revision 5 corrected this on the base side and left the delivered side singular. Same defect, unswept — issue #70 made `ref` per-target on both sides |
| §2.2: `Judged: … ← derived from policy` | derived from an instruction file | The policy that shipped holds target identities and nothing else. Nothing in it can derive that clause |

**§7's second question is closed.** It did not need the parser it appeared to require.

**"The worker cannot lower its own bar" is now stated honestly.** It was true of the API and false
of the filesystem. Re-derivation at completion is added as the moment the conditions are evaluated.
Without it the invariant is unenforceable by construction.

A narrow consultation found the delivered-ref defect, the missing baseline, the unpinnable prior
charter, and the parser trap. The `Gate:` inconsistency came from reading §2.2 against §2.4.

Not changed: policy stays run-scoped. A durable grant for central sources is real. Its only honest
scope is the source, and §9 already orders that stage after this one.

### Revision 7 — the kinds were never a scale

Building the charter needed to know whether changing a clause's kind was a tightening or a
weakening. Invariant 3 said "add or tighten… never remove or weaken" and never defined either across
kinds, so the implementation invented an order — `Gate` over `Judged` over `Decided` — and enforced
it.

| Was | Is | What falsified it |
|---|---|---|
| §2.2 invariant 3: "add or tighten… never remove or weaken" | the set of requirements may grow, never shrink; the kind is not a rank | `Judged: the interface is understandable` promoted to `Gate:` demands a command that cannot exist. The invented order made that a tightening and a weakening of the reverse — both wrong |
| §2.2 gate condition 3: "a clause is weaker than derived" | a clause the pins still derive is gone | With no rank, "weaker" names nothing. The condition it was reaching for is removal, which is the only shape a weakening now takes |

The correction removes code rather than adding it. A clause is identified by its text, so a changed
requirement is a different clause: "tighten" collapses into add, "weaken" collapses into remove, and
the guard against removal already carries the whole invariant.

It also closes a question §2.2 never answered: an introduced clause that is later derived. Provenance
arriving is not promotion, and derivation is the only thing that may say so.

Found reviewing the charter implementation, not by reading this document — the ordering looked
obvious until a clause that cannot be mechanically checked was written down next to it.

---
### Revision 8 — "once" was two answers

Drafting the authorisation stage found §2.3 and §9 disagreeing about how often a human is asked.

| Was | Is | What falsified it |
|---|---|---|
| §2.3: a work-source repo is authorised "by a human, explicitly, once" | once **per run**, with the durable grant deferred to the work-source stage | §9 already said the run-scoped allowlist "asks once per run, which is right for a CLI run and wrong for a queue". Two sections, two answers, and §9 held the correct one |

Found by two independent architecture reviews of a stage that has not been built. The second
corrected the first: an ask with no transport is **not** a further contradiction, because §2.1
already defines what a source that can only `read` does — it forces every `ask` to block — and §9
orders the work source deliberately. A promise with a stated degenerate mode and a scheduled
mechanism is a dependency, not a defect.

### Revision 9 — a pin was answering two questions, and a verdict two more

| Was | Is | What falsified it |
|---|---|---|
| §2.5: "every target that clause **names**" | "every **selected** target it **governs**" | Nothing lets a clause name a target |
| §2.5 quantified over clauses and targets alone | plus: at least one clause, at least one target | In a repo where the detector finds nothing, `charter derive` writes a zero-byte charter at exit 0 and `check` exits 0 — and `make_run` selects no target. The run that delivers on no evidence at all is the *default* one |
| §2.2: an entailment verdict is "stamped as evidence… naming the clause" | recorded beside its pin; never evidence | It is the only specified non-satisfaction record naming a clause, so completion would accept the record that *created* a clause as proof it was met. **History**: revision 12 records every semantic attempt rather than only the establishing one, and moves the authorisation answer out of the pool by this same row's reasoning |
| §2.5 listing the entailment verdict as a `judged` producer | not a producer of evidence | Amending §2.2 alone left two sections with two answers — the defect revision 8 existed to fix |
| §2.2 invariant 1 listing "the work item" | struck | No target, no ref — revision 6's own test |
| §2.2: "it can never lower the bar" | plus: the record it produces can never certify what that record established | Condition three is *removal*. One record creating a clause and satisfying it removes nothing, so condition three never fires. **The records are separated, not the agents** — §7's first question |
| nothing said when coverage binds | §4 — with the selected set, at authorisation | Refusing an ungoverning clause any earlier refuses every clause, because planning has selected nothing yet |

Four investigations against the shipped charter, and two designs rejected. **Coverage narrowing is
deliberately absent**: a clause governs every selected target, because v1 can derive no narrower
answer from a pinned artifact, and a coverage dial nobody authorised is worse than none. The rejected
pair share one shape — an authority record only a human may write, where *only a human may write it*
was prose the code could not enforce.

**No `purpose` field.** Remove the entailment verdict from the pool and every remaining clause-naming
record is a satisfaction claim — a constant, not a field. The set is closed in §2.2 rather than
assumed: an authorisation answer names the condition that fired, never the clause. **History**:
revision 11 lets condition three name its clause, and closes the set on *never a clause the charter
still holds* instead. Revision 12 lets every authorisation answer name its clause, and keeps it out of
the pool entirely — this row's own move, applied to one more record. Still no field.

### Revision 10 — the refusal reached this repository

Drafting the authorisation stage ran revision 9's new refusal against the repository that wrote it.

| Was | Is | What falsified it |
|---|---|---|
| §2.2: *work runs* stated without qualification | for a repository the detector reads a gate from | **Executed here.** Level-1 detection reads a `Makefile` `test:` target, or `"test"` in `composer.json` or `package.json`. Foundry's own repository has none: `detect-gates.sh` exits 1, `charter derive` writes a zero-byte charter at exit 0, and revision 9 ends that run. The refusal is right; the promise was the overstatement |
| §2.1: `ask` carries "options and a recommendation" | plus the decision, the evidence, and what each option causes | An ask that carries neither evidence nor consequence has moved the work to the human rather than the decision |
| nothing said how long an answer binds | one run, and the ask says so | The baseline re-derives from the pins every run and `Decided:` clauses do not carry forward, so the same base re-asks the same settled question for ever. What ends it is amending the artifact, which no ask offered |
| §8: experiments 9b and 6e | both carry the precondition they turn on | 9b does not refuse when Foundry is invoked inside a clone of the source, because the bootstrap knows nothing of sources. 6e counts items where detection is per repository |

Also corrected outside this document: floor's README claimed *"a run has no way to authorise
itself."* Granting is one named command, which stops an accident and not a worker holding the same
shell — which is what the paragraph beneath it already said.

**Found by three independent reviews of a stage that has not been built**, the same method that found
revision 8. Two of the three read the shipped detector rather than this document.

### Revision 11 — two human decisions, and one question closed

Neither was settled by code, spec or a prior review. Both were escalated and both were decided.

| Was | Is | Why |
|---|---|---|
| §2.2: an authorisation answer *"never names the clause"* | condition three's answer names the clause whose removal it authorises | Lowering the bar is the one direction the model gives no way to narrow, so one answer covered every removal in a run. The pool stays unambiguous under a different rule: **never name a clause the charter still holds**. Completion asks only about clauses it holds, so a removal answer is never consulted |
| §7 q1: judge eligibility open, *"blocks the authorisation stage"* | **closed** — role and information path, never vendor | Fresh, read-only, neither proposer nor implementer, unable to mutate the charter, judging from the pinned artifact and the candidate clause alone. Where no such judge can be formed, semantic provenance is not established and the clause falls to the human — which was already the answer for *not entailed* |
| §2.2: *"nothing stops the same judge producing both records"* | *fresh* stops it | Revision 9 separated the records and said so honestly. Eligibility separates the agents, and could not be claimed until it was a rule |

**No new field, and no new record.** Condition three's answer would be a `human` record like any
other; what changed is which clause it may name and why that cannot collide. **History**: revision 12
found condition three has no answer at all — it refuses — and retired the naming rule this row
settled. The pool is kept unambiguous by the store now, not by what a record may name.


### Revision 12 — the transport was deciding what an answer meant

Drafting the work source found §2.1 making a semantic claim it has no standing to make.

| Was | Is | What falsified it |
|---|---|---|
| §2.1 and §2.5: `receive` returns "that human's answer, **as evidence at trust `human`**" | an attributed answer, bound to the run and the question. Completion produces the evidence | An authorisation answer and a satisfaction answer arrive through the same channel and mean different things. Stamping every answer as evidence made the transport assert that a clause was met, which is completion's judgement and nobody else's. §2.5's trust table carried the same claim one section later |
| nothing said how a question is identified | derived from the run, the **stage** and the clause | Without it a resumed run asks again, an answer to another question is consumed, and an answer to an earlier run is too. **The stage is what separates the two questions**: both name a clause, so without it the answer authorising an introduced `Decided:` clause would satisfy it — revision 9's defect, returning for human answers. **Derived rather than issued**, because issuing means storing, and a stored pending question is the parallel ledger §2.2 refuses |
| a fourth term, the condition that fired, was tried and dropped | three terms | It never discriminates: for one clause at authorisation, either no path established provenance or the judge could not tell, never both. The condition is what the ask must **say**; it is not what the answer must **match**. It was also the one term a resumed run could not recompute, which is how the record below was found |
| §2.2: *"never name a clause the charter still holds"* kept the evidence pool unambiguous | the **stage** keeps it unambiguous | Conditions one and two are asked per clause, and an introduced clause *is* in the charter — so the rule forbade exactly what the model does. It could only ever have held while condition three was the sole clause-naming authorisation answer |
| invariant 4 and §4's lifecycle stamped work-item selection as `human` **evidence** | `human` **authority** | Revision 12 separated run-scoped authority from clause-satisfaction evidence for *answers* and left the same conflation standing two sections earlier. Selection names no clause, so it can satisfy none — it belongs with the authorisation answer, not in the pool completion reads |
| the stage separated the two kinds, and §2.5's record shape carries no stage | authority records leave the evidence ledger | Two `human` records naming one clause differ in no field the shape defines — `name` holds the clause either way. A separation only prose can see is not a separation. Revision 9's move, applied again: remove the record from the pool rather than add a field to sort it. **The stage separates questions; the store separates records** |
| condition one read *"neither path establishes provenance"*, which subsumed condition two | *the judge said no, or none could be formed* | Ambiguous **is** provenance not established, so both conditions fired on every ambiguous clause. Disjointness is what lets the condition drop out of the question's identity — the row above rests on this one |
| condition four was listed among the conditions a human is **asked** on | a refusal, cleared by a separate human command | §2.3 already made it one. Listing it as an ask made *four conditions* mean *four asks*, which is why §2.2's every summary of the gate had to be restated |
| §8's 6d asked for *"confirm the human is still asked"* | *confirm the run refuses* | Condition three is the weakening case, and revision 11 had already made it a refusal. The experiment tested for the answer the model stopped giving |
| nothing said **when** the verdict record is written | before the ask goes out | Written after, a run that stops between judging and asking re-convenes the judge on resume and the defect returns whole. Experiment 6g cannot see it — it resumes a run that has already asked — so 6h kills the run inside that window |
| §2.2 recorded an entailment verdict only beside the pin it established | every semantic attempt is recorded, and a resumed run replays it | *Not entailed*, *ambiguous* and *no eligible judge* establish no pin — so the fact that fired an authorisation condition was the one fact nothing kept, and a resumed run re-convened a judge free to answer differently. The question a human was already holding then derived differently or not at all. **The model did need a durable provenance judgement**; it is not a pending question, because nothing reads it to find an outstanding ask, nothing clears it, and it can never say a clause was met |
| §2.2 gave condition three's *answer* a rule | condition three asks nobody anything | It is a refusal, in this document, in issue #93 and in the shipped code, which exits 12. A rule for its answer implied an answer existed. The remedy was always the one §2.2 already names — a human edits the artifact and commits it — so **only conditions one and two are ever transported** |

Drafting the stage found the transport defect and the condition-three defect. Review found the rest,
and two of those were fixes leaving a contradiction in a section the fix did not reach — this
document's oldest failure mode, committed twice more while correcting it. The verdict record is the
first time it has answered *what happens when a run stops mid-question*.


## 7. Unresolved questions

**Closed since revision 2:** `policy` stays; the target allowlist is its first instance and is
required by §2.3, not speculative.
**Closed in revision 4:** the plugin is `floor` — §6. **Nothing now blocks the run stage** — shipped as issue #67.

1. ~~**Who is eligible to judge?**~~ **Closed in revision 11** — §2.2. Eligibility is a property of
   role and information path, never of vendor or model. A judge is eligible when it is **fresh**,
   **read-only**, is neither the proposer of the clause nor any agent that will implement the unit,
   **cannot mutate the charter**, and judges from **the pinned artifact and the candidate clause
   alone**. Where no such judge can be formed, semantic provenance is not established and the clause
   falls to the human — the fallback that was already the answer for *not entailed*.

2. ~~**Which files define a gate's resolution?**~~ **Closed in revision 6.** The set is what
   Foundry's detector read — knowable, because Foundry authors it (§2.2). What the resolved command
   reaches at runtime stays open, and is named residual. "Wrong toward downgrade is safe" survives
   as a tie-breaker, never as a policy: at its limit everything downgrades and the judge becomes the
   routine path.

3. **Does evidence need to leave the machine?** Runs live outside git by design; Panel's Law 5 wants
   verdicts committed. Publishing evidence into a target is a real need and a second code path.

4. **Who owns the `ref` when a run spans repos with different lifecycles?** v1 assumes targets land
   together. That assumption will break.

5. **Can a session genuinely move between providers?** The run directory is provider-neutral, so the
   *state* moves. Whether a conversation does is a provider question, and the honest answer is no.

6. **Where does promotion counting live?** Panel's "raised three times becomes an oracle" is counted
   by a model. A machine-readable ledger makes it countable by code. **Revision 9 split what must be
   counted across two stores** — semantic verdicts recorded with the charter's pins, satisfaction
   verdicts in an evidence ledger that does not exist yet. Promotion counting reads both, or one
   moves.

7. **How is a unit's boundary decided?** `decide-boundary`'s tells surface in code, not in a plan, so
   planning splits units using the one gate that cannot see them. **The weakest joint in the model**,
   and it does not block the run stage because v1 ships one unit.

8. **Does one `Decided:` answer cover every selected target?** §2.5's completion invariant demands
   satisfying evidence at the delivered ref of **every** selected target a clause governs. A question
   is `run + stage + clause` — no target — so one answer covers a two-target run. Asking a human once
   per target is absurd for *pricing copy signed off*, so either the answer stamps one record per
   target or the invariant stops quantifying over targets for `Decided:` clauses. Nothing forces the
   choice yet: v1 selects one target.

---

## 8. Falsifiable experiments

| # | Experiment | Falsifies | Today |
|---|---|---|---|
| 1 | Rewrite a gate script to `exit 0`; confirm the clause downgrades to `judged` | the pinning invariant | not built — **and this is the one that matters** |
| 1b | Ten ordinary runs — a dependency bump, a new test, a refactor; count how many downgrade | that downgrade is rare enough to mean something | not built |
| 2 | Two targets, one run, one ledger | the run/target split | fails |
| 2b | A two-target run where only the bootstrap declares `tests`; confirm completion blocks on the other target | that a `Gate:` clause on an unreadable target cannot be evidenced | not built |
| 3 | Two runs, same branch name, same machine | workspace isolation | collides |
| 4 | A directory of markdown files as a source — `read` under twenty lines, plus `ask` and `receive` | the work-source contract | no contract to satisfy |
| 5 | A run where all clauses derive; confirm no human is asked | the authorisation gate is not ceremony | not built |
| 6 | A run that introduces one clause with no provenance; confirm exactly one question is asked | invariant 1 | not built |
| 6b | The worker asserts its own provenance for an invented clause; confirm it is treated as introduced | the independence constraint | not built |
| 6c | A clause entailed only by `CLAUDE.md` prose; confirm the judge establishes it and no human is asked | the semantic path earns its place | not built |
| 6d | A clause that *weakens* a prior one, with a judge willing to bless it; confirm the run refuses | the asymmetry — a judge may never permit a weakening | not built |
| 6e | Count how often the semantic path is reached across ten **repositories** — detection is repo-scoped, so ten items in one repo answer once | that semantic is a fallback, not the common path | not built |
| 6f | A judge establishes a clause; run completion with that entailment verdict as the only record naming it; confirm delivery refuses | the second half of the asymmetry — an entailment verdict is not evidence | not built |
| 6g | A judge answers *ambiguous*; the run asks and stops; resume it with a judge rigged to answer *entailed*; confirm the question still derives identically and the human's answer still matches | that recording the verdict makes condition two resumable — a flipped judge is exactly what replay must survive | not built |
| 6h | Kill the run **between the verdict and the ask**, then resume with the judge rigged to flip | the write-ordering, which 6g cannot reach — it resumes a run that already asked | not built |
| 6i | Answer condition one for a `Decided:` clause, then run completion with that answer as the only `human` record naming it; confirm delivery refuses | revision 12's headline separation — an authorisation answer is not satisfaction evidence. 6f tests the same shape for a judge's record | not built |
| 9b | A work item filed in `acme/issues` that names `acme/issues` as a target; confirm refusal — **run it from somewhere other than a clone of the source**, or the bootstrap authorises it and the experiment answers a different question | source is not a target | not built |
| 7 | Move a run directory to another machine and resume it | the portability rule | fails as of revision 1 |
| 8 | Items in repo A, code in repo B, Foundry installed globally | source/target independence | untested |
| 9 | A work item naming a repo outside the allowlist; confirm refusal | `policy` | not built |
| 10 | Deliver after gates pass, then land a commit; confirm completion refuses | the completion invariant | not built |
| 10b | A run whose charter derives no clause, and one whose units select no target; confirm both refuse to deliver | the two non-empty conjuncts | not built — **and both would deliver today** |
| 11 | Detection across ten unfamiliar repos — right, wrong, and *says it cannot tell* | Level-1 convention | untested |
| 12 | Open a shell in a workspace and take over mid-run | the session decomposition | untested |
| 13 | Two units in one run, in parallel, no interference | the unit/workspace split | not built |
| 14 | Skill narrowing vs. kernel's claimed 84% activation | the discovery convention | unmeasured |
| 15 | Panel's own kill criterion — ten runs | whether Panel earns its cost | never run |

Experiments 1, 5, 6 and 9 test the properties this RFC claims most loudly. **Experiment 1 would
falsify the headline.** Experiments 6c–6e decide whether the semantic path earns its place: if 6e
shows it reached on nearly every clause, ordering has failed and it *has* become a general approval
step — cut it and go back to mechanical-only.

---

## 9. The order of the work

Stages, not identifiers. Revision 4 predicted GitHub numbers, and they were false within a day:
issues and pull requests share one sequence, so the numbers this section reserved went to PRs
instead. Worse than dangling — the one prediction that *did* become an issue bound to a different
stage than the RFC assigned it, so a reader following the numbers is misdirected rather than merely
stuck.

Nothing architectural lives in an identifier. What this section carries is the ordering and two
structural claims, and both survive without them.

```
run                 identity, layout, lifecycle, one unit, planning's read-only workspace
  ↓
targets             repo + ref, advisory vs authoritative, no local paths
  ↓
policy              the target allowlist and the bootstrap target, enforced in code
  ↓
charter             clauses, mechanical provenance, pinning, monotonicity
  ↓
authorisation       four conditions — two ask, two refuse; the semantic path and its
                    recorded verdicts; silence when none fire,
                    refusal when a clause grades nothing or the charter holds none
  ↓
evidence            append-only, trust levels, no result parameter, the completion invariant
  ↓
gates               per target, executed by code; retire panel.yml
  ↓
work source         read, publish, ask, receive; TWO adapters — GitHub and a directory
                    and durable grants, scoped to the source — §2.3's run-scoped allowlist asks
                    once per run, which is right for a CLI run and wrong for a queue
  ↓
workspace seam      the worktree adapter, and the interface a container would need
  ↓
delivery seam       branch and PR, separate from the source
  ↓
explain             print every default and its reason

unordered           the learning-loop skill, and contracts-first planning
                    kernel: narrow the evaluate.sh skill list before the model sees it
                    run Panel's kill criterion; publish the count
```

**Two structural claims, kept.** `policy` precedes multi-repo targets, because §2.3 makes the
allowlist a prerequisite rather than an open question. And the charter splits in two: the shape ships
with mechanical provenance alone and is useful on its own, while the semantic path is separable and
abandonable if experiment 6e says it did not earn its place.

The three unordered items depend on nothing here and can run at any time.

Provider neutrality gets no stage. It is a property the contracts either have or lack, and §3 states
the two rules that keep it.

**A GitHub issue that exists carries its real number.** This section does not predict them, and a
document whose Problem section prizes zero GitHub coupling should not bake GitHub's ticket sequence
into its own structure.

---

## References

- [Issue #66](https://github.com/attac-t/the-foundry/issues/66) — the brief
- `plugins/panel/skills/craft-charter/SKILL.md` — the charter artifact this generalises
- `plugins/panel/skills/craft-oracle/SKILL.md` — gates as commands, the Coverage Rule, and the
  indirection that break 4 exploits
- `plugins/panel/skills/craft-verdict/SKILL.md` — `branch @ sha`, the completion invariant's origin
- `plugins/kernel/hooks/lib/resolve-memory.sh` — the convention pattern being extended
- `plugins/kernel/skills/ground-mechanism/SKILL.md` — the code/model line the vocabulary rests on
- `plugins/kernel/skills/ground-delegation/SKILL.md` — where a unit's *brief* comes from
- `plugins/panel/skills/decide-boundary/SKILL.md` — why the learning loop and contracts-first left
