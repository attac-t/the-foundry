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

## Use

```bash
sh bin/run.sh new "Ship the gift card flow"
sh bin/run.sh path
sh bin/run.sh home
sh bin/run.sh bootstrap
sh bin/run.sh targets
sh bin/run.sh targets add https://github.com/acme/api.git main
sh bin/run.sh policy
sh bin/run.sh policy authorize https://github.com/acme/api.git
sh bin/run.sh charter
sh bin/run.sh charter derive
sh bin/run.sh charter check
sh bin/run.sh evidence
sh bin/run.sh evidence record tests composer test
sh bin/run.sh gates
```

`new` makes a run and points this checkout at it. `path` prints the active run, or exits 1.

**Making a run changes nothing in any repository.** Allowing that is a later gate.

---

## Where a run lives

```
${FOUNDRY_HOME:-$HOME/.foundry}/runs/<date>-<slug>-<short id>/
├── item.md            what someone wants, and advisory targets
├── bootstrap          the repo Foundry was invoked from — 0 or 1
├── evidence           one line per gate that ran, tab-separated
├── memory/            working.md, blueprint.md, spec.md, adr/
├── planning/          scratch space for planning
└── units/
    └── 01/
        ├── memory/
        └── targets    authoritative
```

The short id is the first free slot. It says nothing about the work, and exists only to stop two
runs from one title on one day landing in one directory.

**Slots are reused, but never while anything still speaks for one.** Delete a run and the next one
with that date and title takes its number back, so a pointer that outlived its run resolves to a
different attempt.

That was harmless while nothing outlived a run. Grants do: they live under `policy/`, not under the
run, and deleting a run leaves them. A reclaimed slot therefore used to hand the next run an
allowlist nobody granted it. A slot is now free only when neither `runs/` nor `policy/runs/` holds
it, which is why the second run in a day can land on `0001` with no `0000` in sight.

Anything else that outlives a run must join that check. The evidence ledger does not — it lives
inside the run and is deleted with it, so a reclaimed slot inherits no record it did not write.

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

`Gate: tests`, never `Gate: composer test`.

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
| `unpinned` | a gate with no pin on this repository |
| `unresolved` | a gate whose resolution record is gone |
| `forged` | a clause whose text is not the text its id was made from |
| `ambiguous` | one id naming two meanings |
| `uncheckable` | a pin on another repository — **printed, but the command still exits 0** |

`uncheckable` is the one finding that does not fail. Every multi-target charter has one, and failing
on it would make `check` useless for the shape it exists to support.

Both drift findings exist because they catch different hands. Editing `.foundry/gates` moves a sha.
Adding a file the detector prefers moves the answer while every pinned sha still matches.

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

### What `check` cannot see

**A deleted introduced clause.** Every finding but one compares the charter against something outside
it — the detector for a gate, the pinned sha for a source, the id for the text. `ambiguous` is the
exception, and it reads the charter alone. An introduced clause has no outside: nothing derived it,
nothing pinned it, and the charter is the only record it existed. Delete the line and `check` reports
nothing.

Closing that needs a ledger the charter cannot edit, which is the evidence stage. Until then a
`Decided:` clause is exactly as durable as the file holding it.

### What this is not

The charter is a file the worker can write, as the same user. `check` catches accident and
unattended drift. It does not resist a worker editing the charter and its pins together.

Containment is the workspace boundary's, and it does not exist yet.

### Only this repository, for now

`charter derive` reads the repository it is run in, and refuses to run anywhere else. A target is
declared and never cloned, so there is nothing on disk to read for any other target until the
workspace seam lands. Deriving clauses for a repository nobody checked out would be introduction
wearing provenance.

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
today; `composer test` in a two-repo workspace is otherwise ambiguous.

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
does this run touch*. After it, the frozen record is, and the live file's authority ends — which is
what lets completion grade against what was authorised rather than against what the file says now.

**The same honest limit as policy and the charter.** The frozen record is a file the worker can write
as the same user, and deleting it silently un-freezes the run — the next authorise records the new
set as if it were the first. Nothing here stops that. What it buys is that no *accident* moves a
selection after it was fixed, and that a moved one is visible to anything that reads both.

### Two conditions are consumed, not computed

Condition 3 is `underived_gates`, which `check` already reports. Condition 4 is `is_authorised`,
through the read-side check. Authorisation asks neither question a second time — a third writing of
either is the tell that the boundary is wrong.

**Condition 1 blocks rather than asking.** An introduced clause is a bar nobody authorised; the run
cannot proceed on it and cannot ask about it, because asking needs a work source. §2.1 already says
what a source that cannot ask does — it forces every ask to block — so that is what happens, visibly
and with the clause named.

**Condition 2 collapses into it.** No judge exists, so nothing reaches the semantic path: every
clause the mechanical path cannot establish arrives as introduced instead. The gate therefore blocks
more often than it eventually will, never less. Nothing durable records the ambiguity, because there
is nothing yet that could answer it.

**Not here yet:** the ask, and the answer.

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
