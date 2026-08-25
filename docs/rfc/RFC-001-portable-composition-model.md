# RFC-001: The Portable Composition Model

**Status:** Accepted — revision 16, 2026-08-22
**Plugin:** `floor`
**Author:** Christian Attard
**Date:** 2026-08-12
**Issue:** [#66](https://github.com/attac-t/the-foundry/issues/66)

The contracts here bind until a revision changes them. Every claim about what is *built* is dated
at the revision above — code ships between revisions, so `plugins/floor` (README, tests, code)
answers what runs now, and §6's revision log is history, never current state.

---

## Abstract

Foundry's ideas are right and its contracts are prose. This RFC names the execution chain the model
was missing — **run, unit, workspace, session** — separates the *declaration* of a target from its
*checkout*, and turns the definition of good into an artifact whose clauses are **derived by code
where truth is mechanical, verified by an independent judge where meaning already exists, and
decided by a human only where new meaning appears.** Five contracts, all of them shapes rather than
files. No coordinator, no registry, no graph engine, no schema language.

**Most revisions here were forced rather than chosen** — by a review, a competing design, or code that
falsified a sentence written in it. The rest settled a question only a human could. §6 records each
one, what it claimed and what moved it.

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
`composer test` approves an indirection whose meaning the worker controls.** The deepest break, and
what §2.2 exists to close.

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

Cardinality is the proof these are distinct.

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

| Word | Means | Enforced by |
|---|---|---|
| `context` | what a model may read | nothing — a model may ignore it |
| `policy` | what code refuses | code |
| `evidence` | a stamped record answering whether a clause was met | provenance |
| `authority` | a stamped record that a human permitted something — this run, or one clause's existence | attribution |

**None of the last three can be minted through an API, because none has one.** All three are still
files a worker running as the same user can write by hand, and v1 does not close that — §2.2 and §2.5
each name what a forgery there would buy.

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

**Both name a clause, so naming cannot tell them apart. Who asked can.** A question is:

```
question = run + stage + clause
```

| Term | Is | So an answer cannot |
|---|---|---|
| `run` | the run that asked, **unique over all time** | reach a later run |
| `stage` | **the reader** — authorisation, or completion | satisfy a clause whose existence it authorised |
| `clause` | its text, so an edit is a new clause | answer a requirement that has since changed |

**`run` must never be reclaimed, and today it is.** Floor reserves a slot only while a grant names it,
so a run that authorised nothing frees its name when its directory goes — and the same base then
mints the same id and the same clause id, giving a later run a byte-identical key. Verified by
running it. Nothing breaks while questions live only in the run; the moment one is asked somewhere
that outlives it, the first run's answer matches the second run's question.

**`stage` is the reader, not the moment.** Authorisation is re-evaluated *at* completion — §2.2 — so a
clock would stamp both questions alike and collide them.

**Nothing else is in the key.** Revision 12 also tried the condition that fired, and it never
discriminates: one clause at authorisation fires exactly one condition, and the question is *may this
clause exist* either way. A condition is what the ask must **say**, so the human knows why they are
being asked. It is not what the answer must **match**.

**Derived, never issued.** A resumed run recovers all three from what it holds — where it is, which
stage is asking, and the charter. So it finds its own question rather than asking twice. Issuing an
identity would mean storing it, and a stored pending question is the parallel ledger §2.2 refuses.

**But a stable identity is not a stable question.** Whether a clause is asked about at all turns on a
judge, and a judge re-convened on resume may answer differently — so a question someone is already
holding can stop existing while its identity stays perfectly derivable. That is why §2.2 records what
the judge answered and replays it.

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
| 1 | **Provenance** | Every clause names the human-owned artifact it came from — a repo script or an instruction file — **and establishes the link by one of exactly two paths, mechanical or semantic (below).** A clause that establishes neither is *introduced*. **History**: revision 13 adds what the resolver *answers* to what the artifact *contains* — deleting a declaration drops detection a level, and every remaining pin still matches |
| 2 | **Pinning** | That artifact is captured at the **base commit** of the target it came from. Both the clause *and its resolution* are pinned. **History**: through revision 12 this read "the base ref — §2.3's `ref`", and §2.3 admits a branch, which moves as the run commits |
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

**Revision 16: the code refuses, and the downgrade above never shipped.** `check_charter` runs first
and exits 7 on drift — a moved pin is a command nobody authorised. Refusal is stricter than the
paragraph below asks for, and it is the honest form of a downgrade with nowhere to go: `judged`
names an independent judge as its producer, v1 has none, and a clause routed to nobody can never be
satisfied. Refusing says so at once and names the remedy. Downgrading would have said it later, from
a stage that cannot answer.

The paragraph below stands as the reasoning, not as the contract. A judge existing changes which is
right, and nothing else does.

Downgraded, not voided. Legitimate work changes test scripts — adding a suite is good. Voiding would
punish it. Downgrading says the exit code no longer speaks for itself and something that is not the
author must look. One `git diff`, no machinery.

**The residual, and it is wider than this section claimed.** A worker can leave the command intact
and change what it reaches — `phpunit.xml`, a bootstrap, an environment file. **It can also change
the gate's own script.** The comparison above is between two resolved command *strings*;
`sh bin/check.sh` is the same string whichever way that file is written.

Run on 2026-08-22 against `main`, in a throwaway repository with one declared gate: the gate failed
(`gates` 14, `complete` 15), the worker rewrote the script to `exit 0` and committed inside the run,
`charter check` answered 0 because the pinned declaration never moved, and `gates` and `complete`
both answered 0. **A run lowered its own bar and reached deliverable**, which invariant 1 forbids.

Neither refusal nor the downgrade reaches it. Closing it is a choice between refusing a run that
edits its own evaluator, grading such a run with the base copy of that evaluator, or recording the
move and finding something able to act on it — open on #66, and nothing is built until it is answered.

**Revision 17: the second option was chosen and built.** `gates` takes every file a pinned command
reaches from the base commit before it runs anything, so a run that rewrites its own evaluator is
graded by the evaluator it agreed to. Only those files. Everything else the run changed is still what
is graded, and a run improving a gate delivers on its other work.

The base blob is planted in a tree holding the work rather than the base tree being checked out. No
gate changes, here or anywhere: a script anchoring to its own root still lands on the work, because
the script sits inside it.

**Reach, not mention.** `sh bin/gates.sh` names one file and runs five more, so the substitution
follows `sh x`, `bash x`, `. x`, `source x` and `awk -f x` to a fixed point. What a script only
mentions is left alone — a gate naming a file in a message would otherwise have the run's own work
graded against the base, which is the same failure pointing the other way.

**A second path was open and is closed too.** `evidence record` ran any command under any name, so
`evidence record gates true` wrote a machine pass for a gate that never ran and `satisfied` took it.
That needed no edit and left no diff. A name the charter pins to a gate is now refused, exit 2, and
only `gates` may answer it.

**What is still open.** A path built from a variable is not followed. Here that boundary falls
between the gate harness and the suites the harness invokes by expansion — and a plugin's suite is as
often a run's work as it is its bar, so following it would make adding a test impossible. That is
luck rather than design.

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

**The honest limit** here, §1's again: coverage is a function of `units/NN/targets`, a file the worker
can write as the same user. Policy
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
nothing anywhere asks *which questions are outstanding* and gets an answer. Nothing clears it either.
**A pending-question ledger would be both of those things**, which is what makes them the test. That
it can never say a clause was met is a separate guarantee, and it separates the record from evidence
rather than from a ledger — a ledger could not say so either.

**This is Panel verifying, not Panel planning.** The judge is handed a candidate clause and asked
whether meaning already exists. It proposes nothing.

#### The authorisation gate

Four conditions fire on a clause or on a target. The rest of this document calls them by number.

| | Fires when | Does | Because |
|---|---|---|---|
| **one** | no provenance — the judge said no, or none could be formed | **asks** | new meaning was introduced |
| **two** | no provenance — the judge could not tell | **asks** | the meaning is genuinely unclear |
| **three** | a clause the pins still derive is gone | **refuses** | invariant 3 was violated |
| **four** | a target is outside the allowlist | **refuses** | policy refuses — §2.3 |

None of the four fires → **no human is asked, and the run proceeds**, unless the charter does not yet
describe work at all — below. That is issue #66's convention test satisfied: *mark/select work → work
runs*.

**For a repository the detector reads a gate from.** Level 1 reads three things — a `Makefile` `test:`
target, or `"test"` in `composer.json` or `package.json` — and a repository holding none of them
derives an empty charter, which the refusal below ends. Foundry's
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
which is what lets a question be named exactly — §2.1. Condition four is a policy refusal whose
remedy is a separate human command, and condition three is a refusal whose remedy is a commit.

Revision 11 decided that if condition three ever *did* carry an answer, that answer would name the
clause whose removal it authorises, one clause at a time. That constraint stands and binds nothing
today, because there is no such answer.

**Revision 11 also kept the evidence pool unambiguous by a naming rule — never name a clause the
charter still holds — and revision 12 retires it.** The rule cannot survive conditions one and two
being asked per clause: an introduced clause *is* in the charter, so its authorisation answer names a
clause the charter holds, and the rule forbids exactly what the model does. **The store does that job
instead** — §2.5 keeps authority records out of the pool entirely, so what they name stops mattering.

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

**The honest limit**, §1's, in this section's terms: the charter, its pins, its verdicts and the
authority record are all files the worker can write, as the same user. Re-derivation catches accident
and drift, not a worker editing them together. **A forgery here buys exactly one thing** — a forged
`entailed`, or a forged answer, buys the silence where a human would have been asked. Never a lower
bar: that is condition three, and it refuses. Closing it is the workspace boundary's job, and the
boundary does not exist yet.

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

**A pin's ref is always a commit**, and that is narrower than this. A branch names where work happens
and moves as the run commits, so a clause pinned through one is a clause whose artifact the run can
rewrite — issue #99, found in shipped code. Selection still takes any of the three; provenance takes
a commit.

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

**The file is one answer, and the thing that answers is replaceable.** A resolver takes a directory
and prints one `name source command` per line; the shipped one reads this file, falls back to
detection when it finds none, and `FOUNDRY_GATES` names a different one. It is the only place an
ecosystem may be known — which is what makes replacing it cheaper than extending it, and why a
resolver that understands a build system nobody here has heard of changes nothing above it.

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

No `unit`, no `ref`. An authorisation answer authorises a clause's existence, which no ref makes
truer; selection has neither, because **it happens before the run does** — §4 selects the work item,
and the stamp lands with the ledger at run creation, naming the run it authorised. **A record without a `ref` cannot satisfy the completion invariant**, which
quantifies over the delivered ref of every selected target. That is the separation, in the shape
rather than in a sentence about it.

**Drop either half and the completion invariant is back to guessing** — §2.1's stage keeps an answer
from reaching the wrong reader; this store keeps a record from reaching one at all.

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

**One yes currently outranks any number of noes**, because the ledger is append-only and satisfaction
is read existentially. Nothing says what a second, contradicting record about one clause and one ref
means. Harmless while every record comes from a command's exit code; not harmless once a human can
answer, and the second human can disagree. **Open — §7.**

**The first two conjuncts close fail-opens, not edge cases.** The invariant quantifies over clauses
and over targets, so an empty charter and an empty selection each satisfy it vacuously. Every fresh
run has the second; any repo the detector reads no gate from produces the first.

**Per target, because there is no run-level ref.** A clause spanning two targets is satisfied
against `acme/api@sha1` *and* `acme/web@sha2`; "the delivered ref" names neither. Revision 5 fixed
this on the base side and left the delivered side singular.

Panel already had this — `craft-verdict:67` stamps `branch @ sha`. Revision 2 dropped it. This is
also why `Decided:` clauses need no second gate: they are clauses, so completion waits for them.

### 2.6 Named seams, contracts deferred

Revision 2 said delivery "needs no shape of its own." That denied a contract rather than deferring
one, while §3 promised adapters could be swapped without touching neighbours — which is impossible
when an adapter's interface is unstated.

These are **seams**. Their contracts are deliberately unwritten, and until written they are unproven
under the two-adapter rule.

| Seam | What plugs in | Starting sketch |
|---|---|---|
| `workspace` | worktree, container, VM, cloud sandbox | create · run commands · expose a service · keep or publish a branch · destroy |
| `delivery` | branch and PR, patch, direct push | publish a result, stamp evidence |
| `browser` | Playwright, and its peers | named in issue #66; no sketch yet |
| `session` | provider-specific attach | no sketch; see §4 |
| `agent` | Claude Code, and its peers | orchestrated, never wrapped — §3 |

The workspace sketch comes from the independently written synthesis §5 compares this RFC against. A
sketch, not a ratified contract, and kept because it beats nothing.

**The workspace seam costs more than the others.** §2.2 and §2.5 admit the same hole — authority,
evidence and policy are files a worker running as the same user can write by hand. A workspace
boundary is what closes it, so three separations in this document are partly standing in for a
runtime that is not here.

A commercial one now exists, open source, with credentials unreachable from agent-written code. That
makes it a candidate second adapter and nothing more — **adopting a runtime is a workspace adapter,
and building one is a different product**.

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

### What kind of thinking the work needs

A worker is replaceable. **What the work needs is not**, and until now the model had no word for it.

| Capability | The work needs |
|---|---|
| `build` | a bounded change made against a stated bar |
| `challenge` | a premise attacked, and what is false found |
| `judge` | a verdict from something that did not produce the thing |
| `read` | a cold reading, reporting confusion rather than resolving it |

Four, because removing any one reproduces a failure this repository has had. Without `build` nothing
changes. Without `challenge` a false premise survives — #150 exists because one did. Without `judge`
the `judged` trust level has no producer, which is exactly why it does not ship. Without `read` a
README that took eight minutes to understand passes every gate.

**The falsifier is collapse.** If two of these always reach the same worker across ten work items,
they were one capability and this table is one row too long.

**A capability is core language. A worker is not.** `build` is what the work needs; whichever product
does it is the adapter's business, the same rule that keeps `foundry:defect` out of core.

**The strongest available worker takes it, and cost is not in that sentence.** Cost is a fact worth
recording and never a reason to lower a bar. A rule holding a cost term is a rule that sometimes
prefers a weaker answer.

#### The fifth is a human's, and so it is not a capability

*Deciding* is missing from the four, and it stays missing. A choice between two defensible options is
authority, not thinking — `Decided:` is a charter kind for exactly that reason, and no worker may hold
it however well it reasons.

So the table is short because one row was moved, never because nobody thought of it.

**Anything else unnamed is unnamed.** Nothing here claims four is the complete set of ways work can
need thinking. It is the set whose absence has cost this repository something, and a fifth arrives by
costing something too.

#### What a record may narrow, and what it may never decide

Two lists, and the line between them is #218's: an observation says a thing happened.

| May narrow | May never decide |
|---|---|
| which worker is offered the work first | whether a clause was met |
| how much effort is asked for | what the bar is |
| whether to ask a person before starting | whether a run may deliver |
| — | who authorised anything |

**Narrowing is a preference between things already allowed.** Deciding is what makes one of them
allowed, and no count of past runs does that.

The rule that keeps them apart: **a record may reorder a set it did not create.** If routing had to
add a worker to be useful, it would be granting.

#### The choice is a row, not a number inside something

A routing decision is written where every other fact about a run is written:

```
<when>	<host>	work.routed	capability=build effort=high because=<what narrowed it>
```

Readable with `cat`, appended once, and granting nothing — the same shape and the same weight as
`gate.finished`.

**A number inside a chooser is not a decision anyone can disagree with.** A row is, and disagreeing
with it later is what makes the choice improvable.

**A wrong choice survives being wrong.** Observations are append-only, so the row that routed badly
stays exactly as it was, and the row that says what happened next sits beside it. Nothing edits the
first, which is the whole reason a later reader can tell the two apart.

#### What none of this proves

**No router exists.** The vocabulary, the lists and the row shape are written before the thing that
would use them, deliberately — a router built first would have invented them quietly.

**The collapse falsifier has never run.** It needs ten work items routed across the four capabilities,
and nothing routes.

**A second harness has never been asked.** The claim that the same work reaches the same capability
under a different harness rests on the word *capability* being provider-neutral, which is a property
of this table and not a measurement.

**Nothing fails when a provider name appears in core.** §3's fixed list records that `run.sh` names
none and `join.sh` names one. A check would need a list of today's vendors and a carve-out for the
plugin format, which dates faster than the sentence it replaces.

### The two-adapter rule

**A contract is unproven until two adapters satisfy it.** In v1 only the work-source contract meets
that bar, and it must — a single GitHub adapter is a GitHub model wearing a costume. Every seam in
§2.6 is unproven and marked so.

Falsifiable form: **a directory of markdown files must work as a work source in under twenty lines**
for `read`, and must be able to `ask` by writing a file and `receive` by reading one.

---

### What is fixed

The two-adapter rule says which contracts are unproven. §2.6 lists the seams. **Neither says which
mechanisms are not going to be replaced at all**, and that list has never existed — so it was being
written by accident, one commit at a time.

The test, and it is the same question every new capability must answer:

> **If the owner rejects this mechanism, what must change?**

Run against v1, counting call sites rather than intentions:

| Mechanism | What must change | |
|---|---|---|
| GitHub | one adapter file. Core names it four times, all in comments, none in code | replaceable, **proven** — a directory answers |
| a CI service | nothing. Gates run wherever `sh` runs | replaceable, **proven** — this repository's have run nowhere else for weeks |
| a container runtime | nothing. No shipped file holds one | replaceable, unproven |
| the harness | `join.sh` only — it reads a rules directory and a settings file that belong to one product | **fixed**, and narrowly |
| the plugin format | every manifest, the marketplace, and the version floor reads about itself | **fixed** |
| **git** | **`target`, `evidence`, `delivery`, and 59 call sites in core** | **fixed** |

**git earned it.** A `target` is a repository and a ref. Evidence binds a commit. A delivery is a
branch. Remove GitHub and a directory answers; remove git and nothing does.

**Fixed is a decision, not a discovery.** Naming git a seam would promise a second implementation, and
by the two-adapter rule a promise with one implementation is a guess. Saying *fixed* costs a port
nobody was making and buys a reader who is not misled.

**The harness row is the surprising one.** `run.sh` names no agent product anywhere. `join.sh` does,
because joining a host means putting plugins where one product looks for them. That is the whole of
the coupling, and it is worth keeping in one file rather than pretending it is absent.

**What would overturn a row.** A second implementation that works. Nothing else — not an intention,
not an abstraction layer written for one caller.

---

## 4. Run lifecycle, and what stays implementation-specific

### The lifecycle

Revision 2 contradicted itself: §2.2 said the charter was approved "before a run starts", while §5
said planning *produces* the run's contents. Planning therefore had no ledger — recreating the
three-ledger disease this RFC diagnoses in its own Problem section.

```
work item selected              ← the human act. Nothing to write to yet
    │
    ▼
run created                     ← the ledger exists. Nothing has mutated
                                  the act above lands here: `human` authority, never evidence
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
or about its removal — it simply grades nothing, so it is no bar. **Changing the selection afterwards
would need a fifth, and v1 has four.** Widen it to a target the allowlist already permits and nothing
fires at all: one, two and three concern clauses, and four tests the allowlist, which allows it. So a
change after the freeze is a new run.

**Planning gets a read-only workspace, scoped to the run.** It must read the targets:
`decide-boundary`'s tells "surface only in code", and gate detection reads the repo. The alternative
— modelling planning as a unit — is circular, since planning is what produces units. The invariant
that matters either way: **planning's workspace cannot mutate a target.**

### Implementation-specific in v1

Named as adapters or seams so none of it becomes ontology.

| Concern | v1 choice | Status |
|---|---|---|
| Workspace | git clone | **seam.** A container, VM or cloud sandbox is equally valid. A worktree shares `.git` with the checkout it came from, so a worker could move that repository's refs — the shipped adapter refuses one by name |
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

**Revision 16: run, and the nouns held.** A person can read the run, because the workspace sits inside
it and the ledger is four levels up. **Floor cannot.** `active_run` reads `FOUNDRY_RUN` or the
invoking checkout's pointer, and never where it is standing — so a shell opened in the workspace gets
nothing from `path` and exit 1 from `gates`. The checkout records `foundry.ref`, the ref it was opened
for, and nothing that names the run.

That is the sentence above holding and its promise not being kept. Joining needs no new noun; it needs
`active_run` to look down at its own feet, which is one lookup and belongs to #115.

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
| 16 | Convention over configuration | The synthesis's three levels, with concrete Level 1 content | both |
| 17 | Source independent of targets | Both agreed. Only achieved once targets stopped carrying local paths | synthesis |

**Correction.** Revision 2 claimed neither document named delivery. The synthesis names it in its
Level 1 table. Delivery being a *separate slot from the source* is this RFC's contribution; naming
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
| `kernel` | `resolve-memory.sh` gains one rung above the branch. Byte-identical when no run is active. `CLAUDE_MEMORY_DIR` keeps its meaning — a *base*, branch appended (`resolve-memory.sh:9`, `tests/memory.sh:40`) — **and an active run outranks it entirely**, below |
| `panel` | `panel.yml` retired. The charter contract moves to `floor` so it survives Panel's kill criterion. Panel keeps judging and verdicts. **Its "Floor" term renames to "Bar"** — `craft-verdict:82`, `adversary.md:53` — which frees the word and makes Panel consistent with its own "lower its own bar" language. Two words; it rode with the kernel/signal sweep |
| `signal` | none |
| stack plugins | none |
| existing memory dirs | keep working, untouched, no migration |

**An active run outranks `CLAUDE_MEMORY_DIR`.** Revision 4 said that variable "keeps its meaning" and
never said what happens when a run is also active. Implementing #67 forced the choice, and an
adversary caught that the RFC had ducked it: a user who relocated memory loses that setting silently
the moment a run exists.

Run wins, for one reason. `CLAUDE_MEMORY_DIR` is the base of the *branch* ladder — it answers "where
do branch-keyed memories live". A run is a different organising principle, not a different base, so
there is nothing for the base to modify. The cost is the silence, and the fix for the silence is
floor's announce hook rather than a precedence change.

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

Building the run and its targets falsified three statements. An architecture that cannot be
contradicted by the thing it describes was never load bearing.

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

Not changed: `0..1` is stronger, not weaker — §2.3 says why.

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
was prose the code could not enforce. **History**: revision 12 adds an authority record carrying that
same unenforceable property. It survives where these did not because of what a forgery buys — these
would have *narrowed* a clause, and a forged authorisation answer only buys the silence where a human
would have been asked. §2.2 states the limit rather than claiming the code closed it.

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
| §2.2: *work runs* stated without qualification | for a repository the detector reads a gate from | **Executed here.** Level 1 detection reads a `Makefile` `test:` target, or `"test"` in `composer.json` or `package.json`. Foundry's own repository has none: `detect-gates.sh` exits 1, `charter derive` writes a zero-byte charter at exit 0, and revision 9 ends that run. The refusal is right; the promise was the overstatement |
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

**No new field, and no new record.** Condition three's answer is a `human` record like any other; what
changed is which clause it may name and why that cannot collide. **History**: revision 12 found
condition three has no answer at all — it refuses — and retired the naming rule this row settled. The
pool is kept unambiguous by the store now, not by what a record may name.


### Revision 12 — the transport was deciding what an answer meant

Drafting the work source found §2.1 making a semantic claim it has no standing to make.

| Was | Is | What falsified it |
|---|---|---|
| §2.1 and §2.5: `receive` returns "that human's answer, **as evidence at trust `human`**" | an attributed answer, bound to the run and the question. Completion produces the evidence | An authorisation answer and a satisfaction answer arrive through the same channel and mean different things. Stamping every answer as evidence made the transport assert that a clause was met, which is completion's judgement and nobody else's. §2.5's trust table carried the same claim one section later |
| nothing said how a question is identified | derived from the run, the **stage** and the clause | Without it a resumed run asks again, an answer to another question is consumed, and an answer to an earlier run is too. **The stage is what separates the two questions**: both name a clause, so without it the answer authorising an introduced `Decided:` clause would satisfy it — revision 9's defect, returning for human answers. **Derived rather than issued**, because issuing means storing, and a stored pending question is the parallel ledger §2.2 refuses |
| a fourth term, the condition that fired, was tried and dropped | three terms | It never discriminates: one clause at authorisation fires exactly one condition, once the row below makes them disjoint, and the question is *may this clause exist* either way. The condition is what the ask must **say**; it is not what the answer must **match**. It was also the one term a resumed run could not recompute, which is how the record below was found |
| §2.2: *"never name a clause the charter still holds"* kept the evidence pool unambiguous | the **store** keeps it unambiguous | Conditions one and two are asked per clause, and an introduced clause *is* in the charter — so the rule forbade exactly what the model does. It could only ever have held while condition three was the sole clause-naming authorisation answer. A rule about what a record may name is replaced by a rule about where it lives, never by the stage — the stage is on the question |
| invariant 4 and §4's lifecycle stamped work-item selection as `human` **evidence** | `human` **authority** | Revision 12 separated run-scoped authority from clause-satisfaction evidence for *answers* and left the same conflation standing two sections earlier. Selection names no clause, so it can satisfy none — it belongs with the authorisation answer, not in the pool completion reads |
| the stage separated the two kinds, and §2.5's record shape carries no stage | authority records leave the evidence ledger | Two `human` records naming one clause differ in no field the shape defines — `name` holds the clause either way. A separation only prose can see is not a separation. Revision 9's move, applied again: remove the record from the pool rather than add a field to sort it. **The stage separates questions; the store separates records** |
| condition one read *"neither path establishes provenance"*, which subsumed condition two | *the judge said no, or none could be formed* | Ambiguous **is** provenance not established, so both conditions fired on every ambiguous clause. Disjointness is what lets the condition drop out of the question's identity — **the dropped-fourth-term row rests on this one** |
| condition four was listed among the conditions a human is **asked** on | a refusal, cleared by a separate human command | §2.3 already made it one. Listing it as an ask made *four conditions* mean *four asks*, which is why §2.2's every summary of the gate had to be restated |
| §8's 6d asked for *"confirm the human is still asked"* | *confirm the run refuses* | Condition three is the weakening case, and revision 11 had already made it a refusal. The experiment tested for the answer the model stopped giving |
| nothing said **when** the verdict record is written | before the ask goes out | Written after, a run that stops between judging and asking re-convenes the judge on resume and the defect returns whole. Experiment 6g cannot see it — it resumes a run that has already asked — so 6h kills the run inside that window |
| §2.2 recorded an entailment verdict only beside the pin it established | every semantic attempt is recorded, and a resumed run replays it | *Not entailed*, *ambiguous* and *no eligible judge* establish no pin — so the fact that fired an authorisation condition was the one fact nothing kept, and a resumed run re-convened a judge free to answer differently. The question a human was already holding then derived differently or not at all. **The model did need a durable provenance judgement**; it is not a pending question, because nothing reads it to find an outstanding ask, nothing clears it, and it can never say a clause was met |
| §2.2 gave condition three's *answer* a rule | condition three asks nobody anything | It is a refusal, in this document, in issue #93 and in the shipped code, which exits 12. A rule for its answer implied an answer existed. The remedy was always the one §2.2 already names — a human edits the artifact and commits it — so **only conditions one and two are ever transported** |

Drafting the stage found the transport defect and the condition-three defect. Review found the rest,
and two of those were fixes leaving a contradiction in a section the fix did not reach — this
document's oldest failure mode, committed twice more while correcting it. The verdict record is the
first time it has answered *what happens when a run stops mid-question*.


### Revision 13 — a branch is not a base

Found by attacking the shipped charter, not by reading this document.

| Was | Is | What falsified it |
|---|---|---|
| invariant 2: pinned at "§2.3's `ref`", which §2.3 defines as a branch, tag or sha | a pin's ref is always a **commit** | A branch moves as the run commits, so a clause pinned through one is a clause whose artifact the run may rewrite. `check` caught the drift and named re-deriving as the remedy, which made re-deriving the way to launder an edit into authority — issue #99 |
| invariant 1 was read as covering the artifact's *content* | and what the resolver *answers* | Deleting a level-2 declaration drops detection a level. The clause survives under a different source, every remaining pin still matches, and the bar the worker authored by removing a file is the one that grades them. §2.2 asked for both halves; the code had one |

**A run's own work may satisfy, invalidate or downgrade a requirement. It may never supply one.** The
remedy is a new run, whose base holds the commit and derives from it normally — the rule bars a run
from blessing its own work, not the work.


### Revision 14 — a question that outlives its run

Found by drafting the work source, which is the fifth revision a stage that does not exist has
corrected. It also found that the stage should not be built yet, which is new.

| Was | Is | What falsified it |
|---|---|---|
| `run` in a question's key, with no claim about its lifetime | unique over **all time** | Slots are reserved by grants, so a run that authorised nothing frees its name when its directory goes. The same base then mints the same id *and* the same clause id. Verified by running it — a later run's question is byte-identical to an earlier one's, and an answer left where it outlives a run would match |
| satisfaction read existentially over an append-only ledger | unchanged, and now named as open | One `yes` outranks any number of noes. Invisible while every record is a command's exit code; a defect the moment a second human can disagree — §7 q10 |
| §9 ordering `work source` with durable source-scoped grants | its own stage | `decide-boundary`'s tell: always-on policy and a deliberately-invoked transport activate differently, so they are two homes. The grant is also *scoped to* a source, which §2.3 says confers no authority *over* it — one word apart, and no contract for the difference |

**Two things the work source needs and does not have.** Nothing said who may answer — attribution
records *who*, never whether they may — and nothing says what an ask may disclose when the source and
the target are different trust domains, which §2.3 already calls attacker-controlled.

**The first is settled and cost nothing.** The human whose selection authorised the run may answer:
invariant 4 already names them, so the rule adds no noun and no store. It makes the selector a
bottleneck, which is the honest price — a run exists because they selected it, and their absence
holding their own run is not a defect. §7 q9. **But invariant 4 describes a stamp nothing writes**,
so the work source still waits on that becoming real.

**And the order was about to be broken silently.** §9 runs `evidence → gates → work source`; neither
of the first two exists. Where an answer lives between `receive` and the evidence ledger cannot be
designed into a stage nobody has built. Every reordering in this document is recorded; this one would
have been the first that was not, because nobody noticed it was one.


### Revision 15 — a debt outlived by the text describing it

Found by reading §7 against shipped code rather than against the last revision. Nothing here changes
the model; the document had begun to describe a stage that exists.

| Was | Is | What falsified it |
|---|---|---|
| §7 q9 owing a `who` floor does not write | written at `new`, and completion refuses a run without one | `selector` and `unauthorised_run`. The note survived the stage it was waiting for, which is the failure mode a revision log cannot catch — nothing was reordered and no claim was wrong when written |

**What the record still is not.** `FOUNDRY_WHO` is whatever the environment says, so attribution
names who claimed the selection rather than who made it. §2.3 already places that boundary with the
provider; this only stops the document implying floor closed it.

**Revision 14's own text is left alone.** It says invariant 4 describes a stamp nothing writes, which
was true when written. A revision log is dated history, and correcting it would destroy the record
that the debt ever existed.


### Revision 17 — the evaluator residual is closed, and a second one with it

Revision 16 recorded a run lowering its own bar and reaching deliverable, and left the fix open on a
choice of three. The second was chosen: **grade with the base copy of the evaluator.**

| Was | Is | What decided it |
|---|---|---|
| a run may rewrite the script its gate names | every file a pinned command reaches comes from the base | the experiment in §2.2, re-run against the substitution |
| a pin covers the declaration the detector read | it still does, and reach is covered separately | a pin is provenance; what a command touches is not a sha |
| `evidence record` writes a machine pass under any name | a name the charter pins is refused, exit 2 | one command, no edit, no diff — cheaper than the hole above it |
| completion ends the run | `merge` is a stage past it, and refuses anything that is not the graded ref | #246 |
| a source carries words | it also carries what the work *is*, and core never learns the spelling | #163 |
| nothing says whether two deliveries join | `reconcile` does, without a coordinator | #119 |

**Two are merged and four are delivered.** `evidence record`'s refusal and the base substitution are
in `main`. Closure, `merge`, the work kind and `reconcile` are open pull requests, graded green under
dash. This section records what is built; §9 records what is in the trunk.

**Invariant 1 holds where it did not.** *A run's own work may invalidate authority and never create
it* was false for two days: a run could create the authority to deliver by editing the thing that
judged it, or by writing a record for a command that never ran. Both paths are closed, and the one
that remains is named in §2.2 rather than left for a later reader to find.

**What this does not claim.** Floor is still not a security boundary. A worker holding the same shell
can edit the charter, the practice and the grants, and nothing here stops it. These close accidents
and the ordinary shape of a worker taking the easy path — not an adversary.


### Revision 18 — the order reached its end, and grew three stages

§9 listed eleven stages and no way to say which were built. A reader had to go and look, and two of
the eleven had been finished for days.

| Was | Is | What falsified it |
|---|---|---|
| eleven stages, no state | each stage says built or not, and what is missing | reading the verb table against the list |
| the order ends at `explain` | three stages came after it that nothing predicted | `merge`, `reconcile`, and a work kind |
| *workspace seam* reads as done | one adapter, so §8's two-adapter rule is unmet there | a clone is the only way a workspace is ever made |

**The order itself held.** Every stage was built in the sequence written, and neither structural claim
was contradicted. That is worth recording plainly, because a build order that survives eleven stages
is the part of this document with the least evidence behind it when written.

**What it did not predict is what came after.** Delivery without merge stops at a green pull request.
Two deliveries with no coordinator need a way to ask whether they join. Each new stage answers a
question an earlier stage created, which is the shape a good order produces rather than a failure of
one.

**Two issues are open for work that ships.** #93 and #97 both carry unchecked boxes against verbs
that exist. This revision does not close them — an issue is closed by checking its own list, not by a
document saying the stage is done.


### Revision 19 — the model had no word for what the work needs

Every noun here describes what is done, who may do it and what proves it was done well. **None
described what kind of thinking the work wanted**, so *route this to the right worker* could not be
said without naming a product.

| Was | Is | What forced it |
|---|---|---|
| a worker is replaceable, and nothing says replaceable *at what* | four capabilities, in §3 | #297 asked for the vocabulary before the router |
| telemetry's limits stated for evidence only | stated for routing too | an observation may narrow a choice and may never make one |

**Two lists, and they do not overlap.** Telemetry may narrow: which workers have done a capability
before and what happened, how often a kind of work needed a second attempt, how long one took. It may
never decide: whether a clause is satisfied, what the bar is, whether a worker may act at all, or
that a weaker answer is acceptable today.

**A routing decision is an observation, not authority.** `work.routed capability=... worker=...` is
readable after the fact, sits beside the gate rows from the same run, and is never deleted when it
turns out to have been wrong. That is how a bad choice is shown to have been one.

**Nothing is built.** No router, no registry, no scheduler. This is the vocabulary a router would
need, written first so that building one cannot invent it quietly.

**Unproven.** One harness has ever run this, so *the same work reaches the same capability elsewhere*
is a claim with no second implementation behind it.


### Revision 20 — a run can be graded by two implementations, and nothing said so

#301 asks what may change when a run begins under one runtime and finishes under another. The bar is
pinned at a base commit, so the *standard* cannot move. **The thing applying it can.**

That is not hypothetical. Two holes closed this week: a run could rewrite the gate judging it, and
hand over a pass for a gate that never ran. Evidence recorded before those fixes was recorded by a
grader now known to have been foolable, and nothing in the ledger says which grader wrote it.

| Was | Is | What forced it |
|---|---|---|
| a row says what happened, and never what produced it | `run.began` and `gate.finished` name the runtime | #276 and #277 — the grader changed, and the rows could not tell |

**Recorded, and not yet refused.** Nothing compares two runtimes and nothing blocks on one. The three
answers #301 offers — pin the run to its runtime, allow a newer one under a contract, or allow some
transitions — are all defensible, and choosing between them wants rows to argue from.

**What would decide it.** A run whose gate rows name two runtimes, where the earlier one is known to
have had a hole the later one closed. That is the case where *the same bar, applied twice* stops
being a nicety. Until one exists, refusing would cost every run that spans a merge and buy nothing
measured.

**Read from the manifest, not compiled in.** A version in two places is one that goes stale, and the
one that goes stale is the copy nobody edits.

**Unproven.** The harness version and the host's tools are not recorded, only floor's. A run that
moved between two Claude Code versions still cannot say so.

### Revision 21 — the seams were listed and the welds were not

§2.6 says which contracts are deferred. The two-adapter rule says which are unproven. **Nothing said
which mechanisms are never going to be replaced**, so that list was being written by accident.

#312 ran the question against v1 and found one answer nobody had written down.

| Was | Is | What forced it |
|---|---|---|
| provider neutrality stated as a rule, with no list of exceptions | §3 names what is fixed, with the call sites that earned each row | #312 measured it: 59 `git` calls in core, four `github` mentions and all of them comments |

**git is fixed, and that is a decision.** Calling it a seam would promise a second implementation, and
a promise with one implementation is a guess by this document's own rule. A human may overturn the
row; only a working second implementation should.

**The harness row was not expected.** `run.sh` names no agent product. `join.sh` does — it reads one
product's rules directory and settings file, because joining a host means putting plugins where that
product looks. Narrow, real, and better in one file than denied.

**§2.6's workspace row costs more than it did.** Cloudflare OS shipped an isolate-per-agent runtime
with credentials unreachable from agent-written code, Apache-2.0, in August 2026. So the seam now has
a commercial existence proof and a candidate second adapter.

That matters beyond adapter arithmetic. §2.2 and §2.5 both admit the same hole — authority, evidence
and policy are files a worker running as the same user can write by hand. **A workspace boundary is
what closes it.** Three of this document's separations are partly standing in for a runtime that does
not exist here, and the row should say so rather than reading as a convenience deferred.

**Nothing in §2.6 is promoted by this.** A cost is not a contract, and adopting a runtime would be a
workspace adapter. Building one would be a different product.

**Unproven.** The container and harness rows rest on reading the tree, never on a port. The first
person to attempt one finds what the grep missed.

### Revision 22 — the capability had a vocabulary and no rules around it

Revision 19 named four capabilities. It said what each was for and said a worker is the adapter's
business. It did not say what a record of past work may do with them, and that is where a routing
model turns into a scheduler without anyone deciding to build one.

| Was | Is | What forced it |
|---|---|---|
| four capabilities, and nothing about how one is chosen | two lists: what a record may narrow, what it may never decide | #297 asked, and the answer had to exist before a router did |
| a routing choice with no shape | a `work.routed` row, appended like every other fact | a number inside a chooser is not a decision anyone can disagree with |
| four, with no word on what is missing | *deciding* is a human's, so it is authority and not a capability | the table looked arbitrary until the moved row was named |

**The line is #218's, restated where routing will meet it.** A record may reorder a set it did not
create. If routing had to add a worker to be useful, it would be granting rather than informing.

**Written before the router, deliberately.** A router built first invents its own vocabulary quietly,
and #297 exists because that had already happened once with telemetry.

**Unproven, and there is a lot of it.** No router. The collapse falsifier has never run, because
nothing routes. No second harness has been asked whether the same work reaches the same capability.
And nothing fails when a provider name appears in core — a check would need today's vendor names and
a carve-out for the plugin format, which dates faster than §3's sentence.

### Revision 23 — one word held completion and what came after it

§2.6's `delivery` row said the seam publishes *an outcome*, meaning the branch and the pull request.
#157 needs *outcome* for what happened once the change reached people. **One word, two meanings, in a
document whose contracts bind.**

The second meaning is the one worth keeping. What a delivery publishes is a **result**, and that is
the word here doing no other work.

| Was | Is | What forced it |
|---|---|---|
| `delivery` publishes *an outcome* | it publishes a **result** | one word cannot hold the artifact and what the artifact caused |
| nothing said where completion stops | completion answers *may this run deliver*, never *did it work* | exit 0 and a merge read as success, and neither is |
| the other half unwritten | an outcome may never set completion — **named, not built** | Product does not exist, and writing its half here would invent it |

**Floor's half is the half that can be written now.** Nothing floor records says whether anyone was
reached: not the ledger, not `delivery`, not `merge`. The seven states #157 names — *implemented ·
delivered · released · exposed · reachable · used · valuable* — collapse into one every time nobody
separates them, and floor proves the first two.

**Unproven, and it cannot yet be otherwise.** Nothing produces an outcome, so no code has ever tried
to cross this line. The rule is written before the thing it constrains, for the reason revision 22
was: a system built first names its own words, and then the words are the design.

### Revision 24 — the experiment table answered as of revision 17

§8's fourth column said *At revision 17*. The document is at 24, and the column had not been read
since — so it recorded a shipped defect that closed six revisions ago.

| Was | Is | What forced it |
|---|---|---|
| 12: *the nouns hold, the verb does not* | **passes** | re-run from a workspace: `path` answers the run, `evidence` prints its ledger |
| 15: *never run* | **cannot be run as written** | `.gitignore` holds `.claude/panel/`, so nothing can count ten runs |
| the column header | the revision that last read it | a date-stamped column nobody re-reads is a claim that ages into a lie |

**Row 12 mattered most.** It said `active_run` never looks where it is standing, which was true when
#115 was open and false the day it closed. A reader planning session work would have built around a
defect that was gone.

**Only what was measured moved.** The other rows were not re-run, and the header now says which
revision read them — so the next reader knows exactly how old each answer is.

**Unproven, and it is the shape of the problem.** A column stamped with a revision still ages. What
would end this is an experiment that runs, not a note about when someone last looked, and #351 holds
the nearest thing: six gates driven by one command.

### Revision 25 — experiment 6 had been passing, unrun

Revision 24 dated the column and moved only what it measured. Row 6 said *not built*: a run that
introduces one clause with no provenance, confirming exactly one question is asked.

**It was built. Nobody had run it.**

| Was | Is | What forced it |
|---|---|---|
| 6: *not built* | **passes** | one `introduce`, then `authorise` exits 11, names that clause alone, and posts one question |
| a question needed `source ask` | `authorise` asks | reading the code said otherwise; running it settled it |

**`authorise` posts the question itself.** The refusal at 11 and the comment on the item are one act,
so the ordinary case never calls `ask`. That verb is for a second question, and it refuses at 17 when
this run already sent one.

**Two clauses make two questions, one each** — which is the invariant, stated per clause rather than
per run.

**The cost of finding out was two comments on a live issue.** They were deleted, and a probe against a
real work source should be read as leaving marks until it does not.

**Unproven, and named.** Nothing here answered the question. Rows 6b to 6i still wait on a judge, and
#332 owns producing one.

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

   **That deferral rests on a precondition nothing enforces.** `targets add` appends without limit and
   no refusal counts them, so a two-target run authorises today.

9. ~~**Who may answer?**~~ **Closed in revision 14** — the human whose selection authorised the run.
   Attribution says *who*, never whether they may, so without a rule every commenter on an item is an
   attributed human and the authorisation gate is decoration.

   **It adds no noun.** Invariant 4 already makes selecting the work item the human act that
   authorises the run, so the run holds one attributed human before any question is asked. An
   allowlist invents a second policy store; *anyone who can write to the source* is the provider's
   access control, which §3 forbids a contract from naming.

   **The cost is real and accepted:** the selector is the bottleneck, and nobody may answer for them.
   The first run that legitimately needs a second person is the evidence that would justify an
   allowlist — building one now is guessing.

   **Paid.** `selector` records the human at `new`, completion refuses a run naming nobody, and the
   work source is built. Invariant 4 describes something written.

   **The residual:** the record says who claimed the selection, never who provably made it —
   `FOUNDRY_WHO` is whatever the environment says. Attribution here is a record, not a credential.

10. **What does a second, contradicting answer mean?** First wins is racy. Last wins lets a late
    commenter overwrite. Refusing matches §2.2's *ambiguous escalates* and turns one disagreement into
    a stopped run. §2.5 says nothing, and an append-only ledger read existentially says *yes*.

---

## 8. Falsifiable experiments

| # | Experiment | Falsifies | At revision 25 |
|---|---|---|---|
| 1 | Rewrite a gate script to `exit 0`; confirm the run is still graded by the bar it agreed to | the pinning invariant | **falsified 2026-08-22, closed 2026-08-23.** It fell for the reason §2.2 records: the pin is on the declaration, so `charter check` answered 0 and `complete` went 15 → 0. `gates` now takes every file a pinned command reaches from the base first. Re-run with `bin/gates.sh` rewritten to `exit 0`: the base's copy ran and the suite went red |
| 1b | Ten ordinary runs — a dependency bump, a new test, a refactor; count how many downgrade | that downgrade is rare enough to mean something | moot — there is nothing to count |
| 1c | Hand a pass over for a pinned gate without running it — `evidence record gates true` — then complete | that a record and a claim are different things | **falsified 2026-08-22, closed the same day.** It reached `complete` 0 with no edit and no diff. A name the charter pins is refused at exit 2, and only `gates` may answer it |
| 1d | Rewrite a file the gate runs but never names, three deep | that a pin covers what a command reaches | **passes.** The substitution follows what a script runs to a fixed point. A path built from a variable is not followed, and §2.2 says where that leaves it |
| 2 | Two targets, one run, one ledger | the run/target split | fails |
| 2b | A two-target run where only the bootstrap declares `tests`; confirm completion blocks on the other target | that a `Gate:` clause on an unreadable target cannot be evidenced | not built |
| 3 | Two runs, same branch name, same machine | workspace isolation | **passes.** Two concurrent `open` calls: one built, one refused at 16, one whole checkout, no leftover. `mkdir` serialises the claim |
| 4 | A directory of markdown files as a source — `read` under twenty lines, plus `ask` and `receive` | the work-source contract | **passes.** `lib/source-dir.sh` ships all four verbs, and the two-adapter rule is met for this contract alone |
| 5 | A run where all clauses derive; confirm no human is asked | the authorisation gate is not ceremony | **passes**, on every self-hosted run to date |
| 6 | A run that introduces one clause with no provenance; confirm exactly one question is asked | invariant 1 | **passes.** Run 2026-08-25 against this repository: one `charter introduce`, then `authorise` exits 11 naming that clause and no other, and posts exactly one `floor-question:` comment carrying the run's own id. A second clause makes a second question, one each. `authorise` asks — nothing has to call `source ask` for the ordinary case |
| 6b | The worker asserts its own provenance for an invented clause; confirm it is treated as introduced | the independence constraint | not built |
| 6c | A clause entailed only by `CLAUDE.md` prose; confirm the judge establishes it and no human is asked | the semantic path earns its place | not built |
| 6d | A clause that *weakens* a prior one, with a judge willing to bless it; confirm the run refuses | the asymmetry — a judge may never permit a weakening | not built |
| 6e | Count how often the semantic path is reached across ten **repositories** — detection is repo-scoped, so ten items in one repo answer once | that semantic is a fallback, not the common path | not built |
| 6f | A judge establishes a clause; run completion with that entailment verdict as the only record naming it; confirm delivery refuses | the second half of the asymmetry — an entailment verdict is not evidence | not built |
| 6g | A judge answers *ambiguous*; the run asks and stops; resume it with a judge rigged to answer *entailed*; confirm the question still derives identically and the human's answer still matches | that recording the verdict makes condition two resumable — a flipped judge is exactly what replay must survive | not built |
| 6h | Kill the run **between the verdict and the ask**, then resume with the judge rigged to flip | the write-ordering, which 6g cannot reach — it resumes a run that already asked | not built |
| 6i | Answer condition one for a `Decided:` clause, then run completion with that answer as the only `human` record naming it; confirm delivery refuses | revision 12's headline separation — an authorisation answer is not satisfaction evidence. 6f tests the same shape for a judge's record | not built |
| 7 | Move a run directory to another machine and resume it | the portability rule | **passes.** A run made in a Linux container resumed on Windows; later runs were opened, graded and delivered across Windows and WSL with no container |
| 8 | Items in repo A, code in repo B, Foundry installed globally | source/target independence | **falsified 2026-08-22 — structurally.** `open` builds every workspace by cloning the checkout floor was invoked in, then pointing origin at the target's identity. A target that is not the bootstrap has no source of objects. That is not missing plumbing: cloning locally is what makes `open` need no network, and it is written down as such |
| 9 | A work item naming a repo outside the allowlist; confirm refusal | `policy` | **passes.** Exit 5, and `run.sh` says so at its own line 986 |
| 9b | A work item filed in `acme/issues` that names `acme/issues` as a target; confirm refusal — **run it from somewhere other than a clone of the source**, or the bootstrap authorises it and the experiment answers a different question | source is not a target | **passes, narrowed.** Advice may not name the repository the item was filed in, and `targets add` with no arguments refuses at 28. A human typing the target still holds — self-hosting is that shape done deliberately. The adapter answers `where`; a directory source has no repository, so nothing there is refused |
| 10 | Deliver after gates pass, then land a commit; confirm completion refuses | the completion invariant | **passes.** `satisfied` matches evidence on the ref it named, so a commit after grading unbinds it. Hit for real on 2026-08-21 |
| 10b | A run whose charter derives no clause, and one whose units select no target; confirm both refuse to deliver | the two non-empty conjuncts | **passes.** `unmet_for_delivery` runs `empty_bar` and `empty_selection` |
| 11 | Detection across ten unfamiliar repos — right, wrong, and *says it cannot tell* | Level 1 convention | untested |
| 12 | Open a shell in a workspace and take over mid-run | the session decomposition | **passes.** It did not at revision 17, and that entry stood six revisions after #115 closed. Re-run 2026-08-25 from a delivered run's workspace with `FOUNDRY_RUN` unset: `path` answers the run's directory and `evidence` prints its ledger. `active_run` looks down at its own feet now |
| 13 | Two units in one run, in parallel, no interference | the unit/workspace split | not built |
| 13b | Two deliveries against one target; confirm each is told whether it can join the other | that separation needs no coordinator | **passes.** `reconcile` asks the source what else is open and tries the merge beside the run. No scheduler, no lock, and no run reads another's workspace. Proved on this repository's own queue: three of five clashed |
| 14 | Skill narrowing vs. kernel's claimed 84% activation | the discovery convention | **unmeasured, and the claim is withdrawn.** kernel's README stated 20% and 84% as fact while this row called the second unmeasured. Nothing counts activations, so both are gone and the README says so. The experiment is unchanged and still unrun |
| 15 | Panel's own kill criterion — ten runs | whether Panel earns its cost | **cannot be run as written.** `.gitignore` holds `.claude/panel/`, so a verdict dies with its branch — thirty-seven written here and one tracked by accident. Nothing can count ten runs. #332 owns producing a verdict floor can read |

Experiments 1, 5, 6 and 9 test the properties this RFC claims most loudly. **Experiment 1 falsified
the headline and no longer does** — see row 1 and §2.2. It cost two shipped mechanisms and left one
residual, which is what a falsifying experiment is for. Experiments 6c–6e decide whether the semantic path
earns its place: if 6e shows it reached on nearly every clause, ordering has failed and it *has*
become a general approval step — cut it and go back to mechanical-only.

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
                    recorded verdicts; the authority record, which is not the ledger;
                    silence when none fire, refusal when a clause grades nothing
                    or the charter holds none
  ↓
evidence            append-only, trust levels, no result parameter, the completion invariant
  ↓
gates               per target, executed by code; retire panel.yml
  ↓
work source         read, publish, ask, receive; TWO adapters — GitHub and a directory

durable grants      scoped to the source — §2.3's run-scoped allowlist asks once per run, which is
                    right for a CLI run and wrong for a queue. Its own stage: always-on policy, where
                    the work source is a transport nobody invokes by accident
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

### Revision 18 — what the order reached

Stages, in the order above, against what floor ships on 2026-08-23. Read from the verb table in
`bin/run.sh` and the two adapters, not from this document's own history.

| Stage | Built | What is not |
|---|---|---|
| run | yes | — |
| targets | yes | — |
| policy | yes | — |
| charter | yes | the semantic path. No judge exists, so condition 2 cannot fire |
| authorisation | yes | — |
| evidence | yes | — |
| gates | yes | *per target* means the one target the caller stands in |
| work source | yes | — two adapters, four verbs each, and a fifth this section never named |
| durable grants | yes | `.foundry/practice`, read at the base commit |
| workspace seam | one adapter | a clone. The container interface is unwritten, so the seam is unproven |
| delivery seam | yes | — |
| explain | no | nothing prints a default and its reason |

**Three stages this section never had.** `merge` lands what was graded and refuses anything else.
`reconcile` says whether two open deliveries can be brought together. A work source also carries what
the work *is*, in core's own word.

None of the three was foreseen, and each answers a question the order below it created. Delivery
without merge stops at a green pull request. Two deliveries with no coordinator need a way to ask.
Work arriving with no kind cannot be sorted by anything that does not read the words.

**The order held.** Every stage was built in the sequence written, and the two structural claims below
were never contradicted. What the order did not predict is what came after it.

**One stage is a seam in name only.** A workspace has one adapter, so §8's two-adapter rule is unmet
there and the interface a container would need is still a guess. The work source has two and is the
only seam that meets it.

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
