# floor

> Where work happens.

A **run** is one attempt at one work item. It lives outside every repository it will change.

---

## Why it sits outside

Working memory used to live in the repo being changed. That breaks three ways.

| Case | Before | Now |
|---|---|---|
| Work spans two repos | Two memory folders, no shared record | One run, one record |
| The target is read-only | Nowhere to write | The run is not in the target |
| Two attempts, one branch name | They collide | Two runs, two ids |

---

## Before the first run, on a host that never had one

```bash
sh bin/join.sh
```

It reports and exits. Nothing is installed and nothing is written to the repository.

Six things stood between a clean machine and a working system, and three were silent when wrong: no
`gh` picks a different work source, no git identity fails later at commit, and no `FOUNDRY_WHO`
records an authority nobody granted. Each now names itself.

```
home    /home/you/.foundry-runs
        derived from HOME. Set FOUNDRY_HOME to put it elsewhere.
who     you@example.com
source  a directory, and the remote is GitHub. Install gh, or Issues stay unreachable.
grants  2 in .foundry/practice
gates   1 in .foundry/gates
skill   kernel:craft-sh
skill   signal:economy  — NOT enabled on this host
joined.
```

The host's half is above the line, the repository's below it. Neither is written into the other,
and this command writes neither.

A rule that names a skill is the declaration — there is no second list. `shell.md` says *invoke
`kernel:craft-sh` before the first character*, and on a host where kernel is off that rule does
nothing and says nothing. Now it says.

Exit 1 is something the host must supply. Exit 3 is not a repository this can join.

## From a clone to a delivery

Eleven verbs, in this order, and a standing practice answers for two of them.

```bash
sh bin/run.sh new "Ship the gift card flow"          # a run, and this checkout points at it
sh bin/run.sh source read 7                          # the item's own words, if a source can answer
sh bin/run.sh source kind
sh bin/run.sh reconcile
sh bin/run.sh charter derive                         # the bar, pinned at the base commit
sh bin/run.sh policy authorize https://github.com/acme/api.git
sh bin/run.sh policy merge-to https://github.com/acme/api.git
sh bin/run.sh targets add https://github.com/acme/api.git main
sh bin/run.sh authorise                              # refuses, or says who must answer what
sh bin/run.sh open                                   # prints the workspace — the work happens there

# ... a worker commits in the workspace ...

sh bin/run.sh gates                                  # every gate the charter pins, each recorded
sh bin/run.sh complete                               # may this run deliver? 15 names what is missing
sh bin/run.sh policy deliver-to https://github.com/acme/api.git
sh bin/run.sh deliver "Gift card flow"               # push, then tell the source where it is
```

The two `policy` lines are a human granting this run one repository, once. A `.foundry/practice`
that already names it grants the same thing standing, and then the run reaches `open` with nothing
asked at all.

**Every verb refuses on its own and can be run again.** That is what lets a resumed run re-enter
anywhere, and it is why nothing here runs the eleven for you.

Two need a host. `source read` needs a work source that can answer — otherwise a directory does, and
says so. `deliver` needs credentials to push, and says so at exit 19.

A machine with `sh`, `awk` and `git` runs every verb here. **What a gate command needs is the
charter's, not floor's** — a gate may reach for anything, and on a host without it `gates` refuses at
21 naming the command rather than recording a failure that poisons the ref.

---

## Every verb

```bash
sh bin/run.sh new "Ship the gift card flow"
sh bin/run.sh path
sh bin/run.sh home
sh bin/run.sh runs
sh bin/run.sh bootstrap
sh bin/run.sh targets
sh bin/run.sh targets add https://github.com/acme/api.git main
sh bin/run.sh policy
sh bin/run.sh policy authorize https://github.com/acme/api.git
sh bin/run.sh charter
sh bin/run.sh charter derive
sh bin/run.sh charter check
sh bin/run.sh evidence
sh bin/run.sh evidence record tests ./check
sh bin/run.sh gates
sh bin/run.sh source read 7
sh bin/run.sh source publish work/gift-cards "Gift card flow"
sh bin/run.sh source ask authorisation tests "May this clause exist? …"
sh bin/run.sh source receive authorisation tests
sh bin/run.sh charter introduce Decided "pricing copy signed off"
sh bin/run.sh authorise
sh bin/run.sh open
sh bin/run.sh complete
sh bin/run.sh policy deliver-to https://github.com/acme/api.git
sh bin/run.sh deliver "Gift card flow"
```

`new` makes a run and points this checkout at it. `path` prints the active run, or exits 1.

**Making a run changes nothing in any repository.** Allowing that is a later gate.

---

## Where a run lives

```
${FOUNDRY_HOME:-$HOME/.foundry}/runs/<date>-<slug>-<short id>/
├── item.md            what someone wants, and advisory targets
├── source             which item this run reads — one line, and never a provider
├── bootstrap          the repo Foundry was invoked from — 0 or 1
├── authority          who selected this work item, and when
├── evidence           one line per gate that ran, tab-separated
├── memory/            working.md, blueprint.md, spec.md, adr/
├── planning/          scratch space for planning
└── units/
    └── 01/
        ├── memory/
        ├── targets    authoritative
        └── workspace/ one isolated checkout per selected target
```

The short id is the first free slot. It says nothing about the work, and exists only to stop two
runs from one title on one day landing in one directory.

**A name is never minted twice.** Every run reserves its slot under `policy/`, which outlives the
run directory — so deleting a run frees nothing, and the second run in a day can land on `0001` with
no `0000` in sight.

Reserving on the first grant was not enough. A run that authorised nothing gave its name back, the
same base minted the same id and the same clause id, and a later run derived an earlier one's
question byte for byte — so an answer left where it outlives a run would match the wrong one. Grants
had the milder form of the same defect first: a reclaimed slot handed the next run an allowlist
nobody granted it.

The evidence ledger needs no such care. It lives inside the run and is deleted with it, so nothing
can inherit a record it did not write.

`units/` holds one unit today. The level is there from the first run because adding it later would
move every path in every adapter.

`planning/` is scratch space, and deliberately **not** called a workspace. Workspace is a seam in
RFC-001 with no written contract, this directory holds no checkout, and naming a thing after a
contract that does not exist is the mistake the word `seam` was added to stop. Planning must never
write to a target, and nothing enforces that yet because nothing here reads one.

---

## Targets

A target says **where work starts**. It never says what the work produced.

| Field | Means |
|---|---|
| `repo` | a portable identity, derived from git, credentials removed |
| `ref` | the base ref the unit starts from |

```
target    = where work starts
delivery  = what work produced
```

A branch, a commit or a pull request is delivery. None of it belongs here.

### A repository identity has to survive the trip

A run is meant to move to another machine. So a target may hold no local path, ever:

| Remote | Identity |
|---|---|
| `https://tok3n:x@github.com/acme/api.git` | `https://github.com/acme/api.git` — credentials stripped |
| `git@github.com:acme/api.git` | kept as-is; `git@` is an ssh login, not a credential |
| `C:/repos/api`, `/home/me/api`, `file://…` | **refused** — not portable |
| anything holding a space, a newline or a `..` segment | **refused** — not storable |

A host with no dot in it is a Windows drive letter, which is why `C:/repos/api` cannot pass as
scp-style. When no portable identity can be derived, floor records nothing and says so — it never
writes a path instead.

**Storable is a second question, and it is about the line, not the repository.** Every identity is
one whole line in a file that `grep -Fxq` reads back. A newline in one is therefore two entries: the
allowlist matched on the first and the unit recorded the second, so one grant fetched a repository
nobody authorised. A `..` segment deceives differently — git resolves it, so the line clones one
repository while reading as another in a file whose whole job is being read. Both are refused.

Source-relative names come later, with the work-source adapter. There is nothing for them to be
relative to yet.

### The bootstrap target is optional

**Zero or one per run.** Invoking Foundry inside a repository is the human act that makes that
repository a target. Starting from a central work source, a bare CLI call, or a remote runner later
is equally valid and records none. Absence is an answer, so `bootstrap` exits 1 rather than failing.

A work-source repository never becomes the bootstrap target because an item came from it.

### Two levels, and they are not equal

| Level | Where | Authority |
|---|---|---|
| work-item targets | `item.md` | **advisory** — anyone who can file an item can write them |
| unit targets | `units/NN/targets` | **authoritative** |

Nothing moves one into the other. Naming a repository in `item.md` grants nothing at all — the
allowlist below decides, and `policy authorize` is the only thing that writes to it.

Authoritative targets sit under the unit because a workspace belongs to a unit and targets belong to
a workspace. One unit ships; the level is already there.

---

## The allowlist

**Authorised is not selected.** The allowlist says what a run *may* reach. `units/NN/targets` says
what it *does* reach. `targets add` needs both, and neither implies the other.

```
${FOUNDRY_HOME:-$HOME/.foundry}/policy/runs/<run id>/targets
```

One allowlist per run. A grant for one run authorises nothing in the next, so a run that went wrong
cannot leave a wider reach behind it.

| | |
|---|---|
| the file | what is authorised — read it to know |
| `policy authorize` | the only thing that authorises — nothing else writes here |

The bootstrap target is authorised without a grant. It is the repository a human invoked Foundry
inside, which is the same act. It is **never copied** into the grants file: a copy is a second place
the truth lives, and the two drift the first time a run is edited by hand.

A run with no bootstrap starts authorised for nothing.

### The selection is checked every time it is read

`targets add` guarded the write. Nothing guarded the read, so a line put into `units/NN/targets` by
hand was selected all the same — and every charter clause is graded against every selected target, so
that edit changes what the run answers for. Re-deriving the charter cannot catch it: the charter did
not move, the selection did.

Reading the selection now refuses it — exit 5 — unless every line is a repo and a ref, and every
repo is authorised. It refuses rather than skipping the line, because a run carrying on against a
selection nobody chose is the failure this exists to make loud.

**A line removed by hand is still invisible.** The file is the only record of what was selected, so
nothing can tell a deletion from a selection that never happened. Catching that needs the set written
down at the moment it is fixed, which belongs to the authorisation stage.

### What this is not

**It is not a security boundary.** Grants live outside the run directory, and that buys nothing
against a hostile worker: a worker holding a shell as the same user can edit the grants file
directly, and no arrangement of files on that user's disk can stop it.

Half the allowlist is not out there anyway. The bootstrap entry is read from `<run>/bootstrap`,
inside the run — so "outside the run directory" describes where grants are kept, and nothing more.

What it buys is that **no accident widens authority**. Nothing derives a grant. No command grants as
a side effect of doing something else. Granting is one named command and nothing else reaches it —
which stops an accident, not a worker holding the same shell.

Resisting a worker with arbitrary host-user shell access needs a runtime and workspace boundary that
makes policy state unavailable for the worker to mutate. That does not exist yet. Until it does,
this is a correctness mechanism, not a containment one.

Policy state holds portable identities and nothing else — no local path, no credential. It outlives
the run that wrote it and it gets read by eye.

### Two deliveries, and whether they join

`reconcile` asks the source what else is open against this target, and tries the merge in a tree
beside the run. It names the deliveries it clashes with and the files they both change, and answers
26. Clean, or nothing else open, answers 0.

**Nothing coordinates them.** No scheduler, no lock, and no run reads another run's workspace — a
branch name is all that crosses, and the source is what knows it.

**It never reads as clean when it could not say.** A branch nobody could fetch and a merge nobody
could try are both counted with the clashes. The question was whether these join, and a run that
cannot answer has not answered yes.

Reported, never refused. A clash is a fact about two deliveries and a fault in neither, so delivery
stays exactly where it was.

### Merging is a third grant

`grade` reads and runs. `deliver` proposes. **Neither is landing work in the trunk**, so `merge` is a
grant of its own and absent by default.

`merge` refuses unless the run is authorised, complete, and the delivery's head is the commit its
evidence names. That last one is the contract: a head that moved after grading is a tree nothing
answered for. It also refuses a source that will not take the delivery, a required check that did not
pass, and a check that has not answered — **a pending rollup carries no failure, and a reader looking
for one calls it clean.**

A retry after a merge that already landed says so and merges nothing twice.

**Provider permission is not authority, and neither implies the other.** Anything that can run `gh`
can merge whatever this file says. The grant records intent and withholds nothing; the identity
Foundry runs under is what refuses. `.foundry/practice` opens by saying so, and a human adds the
line — a run proposing its own authority is not a grant.

---

### A kind is the source's word, not Foundry's

`source read` also asks the source what the work **is**. A directory carries `kind: defect` in
frontmatter. GitHub carries a label called `foundry:defect`. Core is told `defect` by both and knows
neither spelling — `source kind` prints it, and exits 1 when the source said nothing.

**A repository's own labels are its own.** A tree Foundry does not own already has `bug`,
`enhancement`, `blocked`. Reading those would make a stranger's vocabulary into Foundry's authority,
so the namespace is the whole of the rule: `foundry:*` is Foundry's, everything else is the
repository's, and nothing crosses without a human.

The literal `foundry:` exists in one file, and floor's own suite fails when it appears in another.
A prefix anywhere else is portability already leaked.

**A kind is not authority and not a bar.** Nothing reads it yet. It widens no allowlist, moves no
clause and selects no target, so a run without one is ordinary rather than blocked.

---

## The charter

What must be true for this run to be good. One file, in the run.

```
clause  <id>  Gate|Judged|Decided  <text>
pin     <id>  <target>  <ref>  <source>  <sha>
gate    <id>  <command>
```

| Kind | Truth | Checked by |
|---|---|---|
| `Gate:` | deterministic | code |
| `Judged:` | meaning or quality | an independent judge |
| `Decided:` | new meaning | a human |

A clause's id is its meaning — not its kind. Fold the kind in and `Gate: tests` and `Decided: tests`
become different clauses, so weakening one goes unnoticed.

One clause may have many pins. A clause whose meaning comes from two repositories names both, each at
its own base ref. Pins are separate records because inline ones make dropping a target and deleting a
clause the same edit, and monotonicity has to tell those apart.

A clause with no pin is **introduced**. It stays introduced. Re-deriving keeps it and never gives it
provenance it did not earn.

### A Gate names a gate

`Gate: tests`, never `Gate: ./check`.

`lib/detect-gates.sh` resolves the name. It is the only file here that may know an ecosystem exists,
and nothing above it learns why. A repository declares its own gates in `.foundry/gates`; detection
guesses when it does not.

The charter pins what the detector read and records what it resolved to. `charter check` runs the
detector again:

| Finding | Means |
|---|---|
| `moved` | a pinned file's sha changed |
| `resolves elsewhere` | the same gate name now yields a different command |
| `deleted` | something derives that the charter no longer holds |
| `unpinned` | a gate the detector yields, with no pin on this repository |
| `unresolved` | a gate whose resolution record is gone |
| `forged` | a clause whose text is not the text its id was made from |
| `ambiguous` | one id naming two meanings |
| `repeated` | one id holding two commands |
| `unprovenanced` | a gate record with no pin at all |
| `unclaused` | a gate record with no clause |
| `notagate` | a gate resting on a clause that is not a `Gate` |
| `uncheckable` | a pin on another repository — **printed, but the command still exits 0** |

The last four read the charter alone. `unpinned` names a gate the **detector** yields;
`unprovenanced` names a **record** in the file. Both are about a missing pin, and they are different
questions — one asks what should be there, the other what is.

`uncheckable` is the one finding that does not fail. Every multi-target charter has one, and failing
on it would make `check` useless for the shape it exists to support.

Both drift findings exist because they catch different hands. Editing `.foundry/gates` moves a sha.
Adding a file the detector prefers moves the answer while every pinned sha still matches.

### A gate is graded as the base wrote it

The pin covers `.foundry/gates`, the file the detector read. It does not cover `check.sh`, the file
the command runs — so a run could rewrite the script grading it, record a pass, and deliver, while
`check` answered 0 the whole time. Nothing a pin covers had moved.

`gates` now takes each of those files from the base before it runs anything. **Only the gate's own
file.** Everything else the run changed is still what is graded, and a run improving a gate is graded
by the gate it agreed to.

The base blob is planted in a tree holding the work, not the base tree checked out. That is why no
gate changes: a script anchoring to its own root still lands on the work.

**A command reaches more than it names.** So the substitution follows what a script *runs* — `sh x`,
`bash x`, `. x`, `source x`, `awk -f x` — and what those run, to a fixed point. `bin/gates.sh` names
no gate script; every one of them is reached this way.

What a script only *mentions* is left alone. A gate naming a file in a message would otherwise have
the run's own work graded as the base wrote it, which is the opposite failure — work nobody could
ever pass.

**A path built from a variable is not followed, and that is where this stops.** Here the boundary
falls between the gate harness and the suites it invokes by expansion. A plugin's own suite is as
often a run's work as it is its bar, so following it would make adding a test impossible. That is
luck rather than design, and it is the residual.

### Monotonicity

The set of requirements may grow. It may never shrink.

**The kinds are not a scale.** `Judged: the interface is understandable` raised to `Gate:` asks for a
command that cannot exist, and `Decided:` carries authority no command can hold. They say how truth
is established, not how much of it there is.

So a human may not change a kind at all. Deciding a requirement is established differently is new
meaning, and new meaning belongs in a committed artifact where derivation finds it. Only `derive`
sets a kind, and only by establishing provenance — which is also what happens when something
introduced later becomes derivable. Provenance arriving is not promotion.

A clause is its text, so a changed requirement is a different clause. Every weakening is therefore a
removal, and the refusal to drop is the whole invariant.

**The baseline is what the pinned artifacts derive now** — never a previous run's charter. A human who
relaxes a rule commits it, and the next base carries it. A buggy derivation would otherwise become
law. So `Decided:` clauses do not carry forward: a decision meant to last belongs in a committed file.

### What `check` reads

Most findings compare the charter against something outside it — the detector for a gate, the pinned
sha for a source, the id for the text. Two do not.

`ambiguous` reads the charter alone. So does `unsound`, which judges every `clause`, `pin` and `gate`
record **as a record**: a gate whose id appears twice, or carries no pin, or no clause, or a clause
that is not a `Gate`. Nothing outside the file answers those, so nothing outside it was asked — and
for four rounds each of those tampers reached the gate stage instead, one refusal at a time.

`awk -v id=123` compared against a field is a strnum, so `$2 == id` matches `0123`: a gate is pinned
to one reader and unheard of by the next. Five such comparisons are still in the runner. What changed
is that the disagreement now refuses — `unsound` keys on subscripts, which are text, so it reports
`unprovenanced` and `unclaused` for the id nobody wrote.

### What `check` still cannot see

**A deleted introduced clause.** An introduced clause has no outside: nothing derived it, nothing
pinned it, and the charter is the only record it existed. Delete the line and `check` reports
nothing.

**A clause, a pin and a gate written together.** `unsound` catches a record missing its half; a whole
triple that agrees with itself contradicts nothing, and every other reader looks outside the file for
an answer this one carries inside it. Writing all three is the same act as editing the charter and
its pins together, which the boundary below already names.

Closing that needs a ledger the charter cannot edit, which is the evidence stage. Until then a
`Decided:` clause is exactly as durable as the file holding it.

### What this is not

The charter is a file the worker can write, as the same user. `check` catches accident and
unattended drift. It does not resist a worker editing the charter and its pins together.

Containment is the workspace boundary's, and `open` holds it.

### Only this repository, for now

`charter derive` reads the repository it is run in, and refuses to run anywhere else. A target is
declared and never cloned, so there is nothing on disk to read for any other target until the
workspace seam lands. Deriving clauses for a repository nobody checked out would be introduction
wearing provenance.

---

## Who the run answers to

A run exists because a human selected the work item. `new` stamps that, once, in `authority`:

```
2026-08-16T21:14:03Z	ada@example.com	2026-08-16-ship-the-flow-0000
```

`FOUNDRY_WHO` names them; `git config user.email` is the fallback every checkout already has.

**Three fields, where evidence has seven, and it is a different file.** This names no clause, so it
can satisfy none — and a record with no `ref` cannot satisfy the completion invariant, which reads
its ledger existentially. Keeping them apart by store is what makes that true; a field to sort by
would not.

**Nobody is an answer, and is written as one.** `new` changes nothing in any repository, so it is the
wrong place to demand a name. Delivery is the right one, and `complete` reads what `new` stamped.

---

## Gates

```bash
sh bin/run.sh gates
```

Runs every gate the charter pins, records each, and answers 14 if any did not pass.

**The command comes from the charter, never from the caller.** `evidence record tests true` writes a
`machine` record for a gate named `tests` that ran `true` — a pass nobody earned. `gates` takes no
command at all, so the only thing it can record is what the pinned command did.

It refuses on drift before running anything. A moved pin is a command nobody authorised, and
evidence for it would sit in the ledger looking exactly like evidence for the one they did.

One ref for the whole set, taken before the first gate. A gate that commits cannot move the tree the
gates after it are recorded against.

Each gate runs with its target's checkout as the working directory — §2.4. One checkout exists
today; a gate named `tests` in a two-repo workspace is otherwise ambiguous.

A recorded command gets `/dev/null` on stdin. The gate list is the loop's own stdin, and a gate that
read it swallowed the gates behind it — but the rule outlives that: evidence of something that waited
on a human is evidence nobody can reproduce. This holds for `evidence record` too. It is the stream,
not the terminal: a gate that opens `/dev/tty` still finds one.

A gate runs where its pin says it came from. One checkout exists, so a gate pinned to another
repository has nowhere to run, and one of them refuses the set. Whether the charter's records hold
together at all is `check`'s question, not this one — see **What `check` reads**.

---

## The workspace

```bash
sh bin/run.sh open
```

One isolated checkout per selected target, under the unit that owns it. Prints where. Opening twice
attaches to what is there and clones nothing again.

**A clone, never a worktree.** A worktree shares `.git` with the checkout it came from, so a worker
could move the source's refs — the isolation this exists for, absent.

**Built beside the slot, renamed into it.** The slot does not exist until the checkout is whole, so
nothing ever reads a half-made one as finished. A creator that dies leaves `<slot>.building`, which
is recoverable and is never mistaken for a workspace. The `mkdir` on that path is what serialises two
sessions — `mv` onto an existing directory moves the source *inside* it and exits 0, so a rename can
never be the thing that refuses.

**A slot's name is decoration; its digest is its identity.** Folding punctuation to `-` put
`acme/a-b`, `a/b`, `a.b` and `a_b` in one directory.

**Twelve characters do not make a collision impossible, and nothing claims they do.** They buy
rarity. What makes a collision *safe* is that attaching compares the origin and finds another
repository's checkout — two targets on one slot is refused, never shared. The guarantee holds at any
prefix length; the length only decides how often a reader meets that refusal.

**The base ref is a label, checked against the run's frozen selection.** It lives in a repository the
worker owns, so a worker can write it — what it is compared against is not. That makes it the same
kind of guard as the charter: it catches a workspace built for another ref, and it does not resist
someone editing both sides. Containment is the runtime boundary's, and there isn't one.

Everything `open` refuses answers **16** — the target was authorised and the home is writable, so 5
and 3 would each name a remedy that changes nothing.

| It says | Means |
|---|---|
| `is not a checkout of` | something else is at that path — yours to remove, not floor's |
| `is being checked out` | another session holds the build path, or one died holding it |
| `has no ref` | the target has no such branch, tag or sha |
| `could not clone` | the objects could not be read from this checkout |
| `appeared while it was being built` | another session published first |

**It may not exist for a run nobody authorised.** `open` runs `authorise` rather than restating any
of its twelve reasons; a workspace is where mutation happens.

Local objects, remote identity: cloning from the checkout needs no network, and the origin is then
the identity the target names — so a branch pushed from here goes where the target says rather than
where this machine happened to be.

**One adapter is not a proven seam.** §3 holds a seam unproven until two adapters satisfy it, and
this is one — a clone, on this machine, of a target this checkout already is. It says nothing about
containers, VMs or sandboxes. A target this checkout is not is named and refused rather than guessed
at: a URL rebuilt from an identity carries no credential.

---

## May this run deliver?

```bash
sh bin/run.sh complete
```

Exit 0 means yes. Exit 15 names what is missing.

§2.5 states three conjuncts:

> A run may deliver only when the charter holds at least one clause, at least one target is selected,
> and every charter clause has satisfying evidence stamped at the delivered ref of every selected
> target it governs.

A fourth is invariant 4's, which §2.5's shape supports without asserting: **a human selected this
run.** Its absence is recorded, so completion can read it.

**The bar is met at a sha, not in general.** Gates could pass at commit N, three commits land, and
delivery proceed on evidence that no longer applied. That is the whole of what this adds.

**The first two close fail-opens, not edge cases.** Quantified over clauses and over targets, the
rule is satisfied by an empty charter and by an empty selection — for free. Every fresh run has an
empty selection, and any repository the detector reads no gate from produces an empty charter.

**And `every selected target` means every one.** One checkout can answer for one of them, so a second
selected target is reported `ungradable` rather than passed over. §8's two-target experiment is meant
to fail today; this is the sentence that fails it.

| Finding | Means |
|---|---|
| `unauthorised` | nobody is recorded as having selected this run |
| `nobar` | the charter holds no clause |
| `nothing selected` | no target, so every clause is satisfied over nothing |
| `unmet` | a clause with no passing record at the delivered ref |
| `ungradable` | a selected target with no checkout here, so nothing can be evidenced at its ref |
| `introduced` | a clause resting on no pin, which no ref can satisfy |
| `unverifiable` | a clause pinned to a repository this checkout is not |
| `nothing delivered` | this checkout has no commit to be graded at |

The last three are not failures and not passes. **They take different remedies, which is why they are
different words.** An `introduced` clause was established by nobody, so the answer is a human's, and
the work source carries one. An `unverifiable` clause belongs to a checkout
that does — the workspace seam is what turns it into an answer.

**It keeps no record of its own.** `new` stamped the selection, the charter holds the clauses, unit 01
holds the selection, the ledger holds what ran. A second copy of any of them is a second thing to
drift.

---

## Authorisation

```
run.sh authorise
```

RFC-001 gives this stage four conditions and two refusals. **Everything that can refuse without a
human present ships here** — both refusals, and the three conditions that resolve to a refusal or a
block. What is missing is the *ask*, which needs a work source to ask through and arrives with it.

| Refused | Because | Exit |
|---|---|---|
| the selection moved since it was authorised | that is a different run | 10 |
| a selected target policy never authorised | condition 4, read side | 5 |
| this run has no charter | there is nothing to authorise yet | 1 |
| the detector yields a gate the charter holds no clause for | condition 3 — re-derive | 12 |
| the charter holds no clause | nothing is described | 8 |
| a clause is introduced | condition 1 — nobody authorised it, and there is nowhere to ask | 11 |
| a clause grades no selected target | a bar that grades nothing is no bar | 9 |

**In that order, and the order carries meaning.** Each refusal names a remedy, and a remedy that
leads to another refusal is worse than one remedy — so the cause always outranks the symptom. An
emptied selection is a *moved* one, not a bar grading nothing. An introduced clause is stopped for
its provenance before its coverage, because *declare that gate* would turn a clause nobody authorised
into a real bar and only then mention it had none.

**A code per remedy, never one code for the stage.** One code would say *refused* and leave the
caller reading prose to find out what to do about it. **The refused run ends.** Re-running planning
against the same pins and the same selection derives the same charter and refuses again, so the
remedy is a gate declared, an artifact amended, or a target selected — never another attempt.

The second refusal has exactly two shapes today: nothing is selected, or the only selected target is
the bootstrap and it declares no gate by that clause's name. Every other selected target is one whose
declarations cannot be read, and an unreadable target **stays governed** — so a clause still grades
it. That is computed rather than assumed, and it answers differently the day each target has a
checkout.

### The selection freezes here

```
<run>/units/01/authorised-targets
```

Authorising writes the selected set down. **That record is what makes a line *removed* from
`units/NN/targets` visible** — the selection file cannot show an absence, and a second record can.
Adding a line is caught either way; deleting one was caught by nothing at all until this existed.

The lines, not a digest of them: a digest answers *something moved* where a diff answers *what*, and
the second is the question a person asks. Sorted, because §2.3 calls it a set — the same two targets
in another order are the same selection, and a refusal that fired on that would teach people to
ignore refusals.

Authorising again over an unchanged selection is not a change and does not refuse. Authorising over a
moved one exits 10 and does **not** re-freeze: quietly recording the new set would let the selection
be edited after the moment it was fixed, which is the entire thing the freeze exists to stop.

**Who is authoritative moves here.** Before authorisation the selection file is the answer to *what
does this run touch*. After it, the frozen record is, and the live file's authority ends.

**`complete` does not read the frozen record.** It reads the live file, through the same
`refuse_unselectable` guard `targets` and `authorise` use — so an edit is refused rather than graded,
but the two answers are compared only by `authorise`, at exit 10. Closing that gap is a stage that
does not exist; naming it is what this paragraph is for.

**The same honest limit as policy and the charter.** The frozen record is a file the worker can write
as the same user, and deleting it silently un-freezes the run — the next authorise records the new
set as if it were the first. Nothing here stops that. What it buys is that no *accident* moves a
selection after it was fixed, and that a moved one is visible to anything that reads both.

### Two conditions are consumed, not computed

Condition 3 is `underived_gates`, which `check` already reports. Condition 4 is `is_authorised`,
through the read-side check. Authorisation asks neither question a second time — a third writing of
either is the tell that the boundary is wrong.

**Condition 1 blocks rather than asking.** An introduced clause is a bar nobody authorised, and this
stage does not put the question. A channel exists — `source ask` — and nothing here reads an answer
back, so the run stops visibly with the clause named rather than proceeding on a bar it wrote itself.

**Condition 2 collapses into it.** No judge exists, so nothing reaches the semantic path: every
clause the mechanical path cannot establish arrives as introduced instead. The gate therefore blocks
more often than it eventually will, never less. Nothing durable records the ambiguity, because there
is nothing yet that could answer it.

**Not here yet:** reading an answer. `source ask` carries a question and `source receive` brings one
back; nothing in this stage looks.

---

## The work source

Where a work item comes from, where a delivery is reported, and where a human is asked.

Four verbs, and **transport is all they are**. What an item means is planning's. What an answer means
belongs to the stage that asked — this carries the words and reads none of them.

| Verb | Carries | Refuses |
|---|---|---|
| `read` | the item's words, into the run | a second, different item |
| `publish` | this run's delivery, answering with its identity | a second, different branch |
| `ask` | a question about one clause | the same question in other words |
| `receive` | the answer, or nothing | an answer handed to it |


### An absence is observed, never assumed

*The item is not there* and *the source could not be asked* are different answers, and each has its
own code — 1 and 20. `gh` exits 1 for both, so the adapter asks a second question: a repository
cannot be absent and an issue can.

A GitHub remote on a machine with no `gh` is answered by the directory adapter, which has never heard
of Issues. That is right — `gh` is not a floor dependency — and it is now said out loud, because a
missing tool otherwise reads as a missing item.

### There is no parameter for what a human supplies

`read` names an item and never says what it holds. `receive` names a question and never says what
came back. That is `evidence record`'s shape one stage over: a worker produces a human's answer only
by writing it where a human's answer lives, and §2.5 already says what that gap is worth.

Silence never returns as an answer — nothing on stdout, and a code saying nothing is there. A refusal
comes back exactly as an approval does, because deciding which one it is belongs to whoever asked.

### A question is derived, never issued

```
question = run + stage + clause
```

| Term | Is | So an answer cannot |
|---|---|---|
| `run` | the run that asked, unique over all time | reach a later run |
| `stage` | the reader — `authorisation` or `completion` | satisfy a clause whose existence it authorised |
| `clause` | its text, so an edit is a new clause | answer a requirement that has since changed |

A resumed run recomputes all three and finds what it already asked, so **nothing holds a list of
outstanding questions.** Such a list is the parallel ledger the charter refuses, and the source is
where the question already lives.


### A delivery's identity is kept, a question's is derived

`run + stage + clause` recomputes, so a resumed run finds its own question and nothing holds a list.
A pull request URL does not recompute — the source assigns it. So the run records it at `publish` and
answers from that before asking.

Not a cache. A delivery's *state* goes stale and floor never asks for it; its *identity* is fixed at
birth. Asking again was the original decision, and it fails on a source that is truthful and still
cannot answer: GitHub's body index is eventually consistent, so *nothing yet* reads as *nothing at
all* — and that is what opens a second delivery.

### Nothing here authorises anything

An answer arriving widens no allowlist, moves no clause and selects no target. An introduced clause
still blocks, with the clause named, whether the source holds a yes, a no or nothing at all.

A work source is not a target either. An item naming a repository is advisory — that repository is
authorised by a human or not at all.

### Two adapters, because one proves nothing

| Adapter | Needs | Holds |
|---|---|---|
| `lib/source-dir.sh` | `sh` | files a person opens in an editor |
| `lib/source-github.sh` | `gh` | issues, and comments under them |

`lib/source.sh` chooses between them, and those three files are the only ones in floor that may know
where a work item lives. Nothing above them learns which answered: the run records the item's id and
the item's own words, so a run carried to a machine with neither installed still means what it meant.

`FOUNDRY_SOURCE` names another adapter. `FOUNDRY_SOURCE_DIR` moves the directory one, which otherwise
sits in the Foundry home.

**What this does not prove.** The second adapter has been driven only by a stand-in on the path,
never by the service — so its own conventions run for real and the service's do not. And an answer
there is one line where a directory holds a whole file: the contract says nothing about an answer's
shape, and the two adapters do not agree on one.

**Who answered is not checked.** RFC-001 §2.1 wants an attributed answer and §7 names one person who
may give it — whoever selected the work item. Attribution is the source's: a file is attributed by
who may write it, a comment by whoever left it, and neither is the identity `authority` records. So
floor carries the words and adds nothing, and the rule lands with the stage that reads them.

---

## Which run is active

```
FOUNDRY_RUN set?   → that run
a pointer here?    → the run it names
otherwise          → none, and `path` exits 1
```

The pointer lives in the git directory, so it is never committed and needs no gitignore entry. A
git worktree gets its own git directory, so it gets its own pointer.

**That is the whole answer to two runs at once.** Parallel runs are parallel worktrees. No lock
file, no scheduler.

---

## What kernel sees

kernel resolves memory from `FOUNDRY_RUN` and from nothing else:

```
FOUNDRY_RUN set?  → $FOUNDRY_RUN/memory
git branch?       → .claude/memory/<branch>     unchanged
otherwise         → .claude/memory              unchanged
```

One variable is the whole handshake. kernel never learns where floor keeps a run and never calls
floor, so each plugin still works with the other uninstalled.

**The cost is real.** A hook cannot export a variable into the session that started it. So a run
found through the pointer is a run kernel cannot see, and memory keeps resolving by branch. floor
says so at session start rather than letting you assume otherwise:

```bash
export FOUNDRY_RUN=$(sh bin/run.sh path)
```

---

## Install

Needs: Claude Code CLI, `sh`, `awk`, `git`. No Python, no Node, no `jq`.

```
/plugin install floor@the-foundry
```

Standalone. Pairs with kernel, which is where the memory rung lives.

If it cannot run, it says so at the top of the next session. Silence means it is working.

---

## Where it runs

| Platform | Shell | Home |
|---|---|---|
| macOS, Linux | `sh` | `$HOME/.foundry` |
| Windows | the Git Bash Claude Code starts there | `$HOME/.foundry`, which Git Bash sets |

Git Bash and native Windows disagree about what a path looks like. That is a runtime concern, and
it stays one: **no file a run writes may hold a machine-local absolute path.** There is no
exception. The pointer holds a run id, not a path, and the home is an environment variable.

---

## Tests

```bash
bash tests/run.sh
```

Two suites, then a deliberate break for every rule that matters. Each one must turn a suite red, and
the run says so if a break failed to apply — a mutation that changed nothing proves nothing.

`model.sh` calls the runner. `install.sh` reads the command out of `hooks/hooks.json` and hands it
to a shell — because a suite that calls the scripts itself proves only that the scripts work, never
that the wiring does, which is where kernel and signal both failed.

---

*One attempt. One record.*
