# RFC-001: The Portable Composition Model

**Status:** Accepted — revision 7
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
| `ask` | a question addressed to a human, with options and a recommendation |
| `receive` | that human's answer, as evidence at trust `human` |

**`ask` and `receive` are why this matters.** A human is asked *where they already are* — the issue,
the ticket, the channel — not in a terminal nobody is watching. That is the difference between human
authority and human interruption, and it is a property of the transport, not of a policy.

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
| 1 | **Provenance** | Every clause names the human-owned artifact it came from — a repo script, an instruction file, the work item — **and establishes the link by one of exactly two paths, mechanical or semantic (below).** A clause that establishes neither is *introduced* |
| 2 | **Pinning** | That artifact is captured at the base ref of **the target it came from** — §2.3's `ref`. Both the clause *and its resolution* are pinned |
| 3 | **Monotonicity** | The set of requirements may grow. It may never shrink. A clause's kind is not a rank on that set — below. **The baseline is what the pinned artifacts derive now, never a previous run's charter** |
| 4 | **Authority** | Selecting the work item **is** the human act, stamped as `human` evidence. It authorises everything derived from artifacts that human already owns |

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
| **Independence** — the judge is neither the agent that proposed the clause nor any agent that will implement the unit | The worker may not certify its own provenance. Panel's Law 4 shape, `tools: Read, Glob, Grep` |
| **Entailment, not endorsement** — the judge answers *"is this clause entailed by artifact X at ref Y?"*, never *"is this a good clause?"* | A narrow question has a defensible negative. A broad one collapses into taste |
| **Three answers, not two** — entailed, not entailed, **ambiguous**. Ambiguous escalates | A judge forced to choose binary will guess, and guessing is how new meaning slips through |

**The judge's power is deliberately asymmetric.** It can *prevent a question* by confirming meaning
already existed. It can never *permit a weakening* — condition three below routes every weakening to
the human regardless of what any judge thinks. So a compromised or over-agreeable judge costs an
unnecessary question at worst; it can never lower the bar.

Every entailment verdict is stamped as evidence at trust `judged`, naming the clause, the artifact
and its ref. Judgements are therefore countable, which is what later lets a recurring one be promoted
into a mechanical check — `craft-oracle`'s promotion rule, unchanged.

**This is Panel verifying, not Panel planning.** The judge is handed a candidate clause and asked
whether meaning already exists. It proposes nothing.

#### The authorisation gate

A human is asked **only** when one of four conditions fires:

```
neither path establishes provenance   → new meaning was introduced
the judge answered "ambiguous"        → the meaning is genuinely unclear
a clause the pins still derive is gone → invariant 3 was violated
a target is outside the allowlist     → policy refuses (§2.3)
```

None of the four fires → **no human is asked, and the run proceeds.** That is issue #66's convention
test satisfied: *mark/select work → work runs*.

The worker cannot dodge the gate, because none of the four conditions is reported by the worker. It
cannot lower its own bar, because lowering *is* condition three.

**When the conditions are evaluated decides whether that is true.** Derived once at planning and
trusted after, an in-flight edit of the charter is silent. So the charter is re-derived from its
pins at completion and compared with what it holds.

**The honest limit**, which §2.5 states for evidence and floor's README for policy: the charter is a
file the worker can write, as the same user. Re-derivation catches accident and drift, not a worker
editing charter and pins together. That is the workspace boundary's, and it does not exist yet.

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
repo writable, it is authorised like any other target — by a human, explicitly, once.

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
| `human` | an explicit person-action, via the work source's `receive` | yes — the gap Panel's charter already names |

Two things produce `judged` evidence: a review finding, and a **clause entailment verdict** from
§2.2. Both are attributed and both are countable, which is what lets a recurring judgement be
promoted into a mechanical check later.

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

> **A run may deliver only when every charter clause has satisfying evidence stamped at the
> delivered ref of every target that clause names.**

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
work item selected              ← the human act. Stamped as `human` evidence
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
authorisation                   ← fires ONLY on the four conditions in §2.2
    │                             otherwise silent, and the run continues
    ▼
mutating execution              ← one workspace per unit; gates run; evidence accumulates
    │
    ▼
completion                      ← every clause evidenced at each target's delivered ref (§2.5)
    │
    ▼
delivery
```

**Creating a run is not authorising mutation.** That separation is the point, and it is what lets a
run be abandoned during planning at no cost — already implied by run-per-attempt cardinality.

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
| 9 | **Human judgement vs human ceremony** | **Synthesis. Revision 2 resolved this by silence, in favour of the position that both issue #66 and the synthesis argue against.** §2.2 now derives what it can, has a judge establish what it cannot, and asks a human only on the four conditions | synthesis |
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
| No completion invariant | §2.5 — deliver only when every clause is evidenced at each named target's delivered ref |
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

## 7. Unresolved questions

**Closed since revision 2:** `policy` stays; the target allowlist is its first instance and is
required by §2.3, not speculative.
**Closed in revision 4:** the plugin is `floor` — §6. **Nothing now blocks the run stage** — shipped as issue #67.

1. **Who is eligible to judge entailment?** §2.2 requires independence from the proposer and from
   every agent that will implement the unit. In a one-unit v1 run that is easy. With N units and a
   shared planner, eligibility needs a rule rather than a convention. **Blocks the authorisation stage, not the run.**

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
   by a model. A machine-readable ledger makes it countable by code.

7. **How is a unit's boundary decided?** `decide-boundary`'s tells surface in code, not in a plan, so
   planning splits units using the one gate that cannot see them. **The weakest joint in the model**,
   and it does not block the run stage because v1 ships one unit.

---

## 8. Falsifiable experiments

| # | Experiment | Falsifies | Today |
|---|---|---|---|
| 1 | Rewrite a gate script to `exit 0`; confirm the clause downgrades to `judged` | the pinning invariant | not built — **and this is the one that matters** |
| 1b | Ten ordinary runs — a dependency bump, a new test, a refactor; count how many downgrade | that downgrade is rare enough to mean something | not built |
| 2 | Two targets, one run, one ledger | the run/target split | fails |
| 3 | Two runs, same branch name, same machine | workspace isolation | collides |
| 4 | A directory of markdown files as a source — `read` under twenty lines, plus `ask` and `receive` | the work-source contract | no contract to satisfy |
| 5 | A run where all clauses derive; confirm no human is asked | the authorisation gate is not ceremony | not built |
| 6 | A run that introduces one clause with no provenance; confirm exactly one question is asked | invariant 1 | not built |
| 6b | The worker asserts its own provenance for an invented clause; confirm it is treated as introduced | the independence constraint | not built |
| 6c | A clause entailed only by `CLAUDE.md` prose; confirm the judge establishes it and no human is asked | the semantic path earns its place | not built |
| 6d | A clause that *weakens* a prior one, with a judge willing to bless it; confirm the human is still asked | the asymmetry — a judge may never permit a weakening | not built |
| 6e | Count how often the semantic path is reached across ten real items | that semantic is a fallback, not the common path | not built |
| 9b | A work item filed in `acme/issues` that names `acme/issues` as a target; confirm refusal | source is not a target | not built |
| 7 | Move a run directory to another machine and resume it | the portability rule | fails as of revision 1 |
| 8 | Items in repo A, code in repo B, Foundry installed globally | source/target independence | untested |
| 9 | A work item naming a repo outside the allowlist; confirm refusal | `policy` | not built |
| 10 | Deliver after gates pass, then land a commit; confirm completion refuses | the completion invariant | not built |
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
authorisation       the four conditions, the semantic path, silence when none fire
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
