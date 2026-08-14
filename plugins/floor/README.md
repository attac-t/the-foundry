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
```

`new` makes a run and points this checkout at it. `path` prints the active run, or exits 1.

**Making a run changes nothing in any repository.** Allowing that is a later gate.

---

## Where a run lives

```
${FOUNDRY_HOME:-$HOME/.foundry}/runs/<date>-<slug>-<short id>/
├── item.md            what someone wants, and advisory targets
├── bootstrap          the repo Foundry was invoked from — 0 or 1
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

Anything else that outlives a run must join that check. Evidence will be the next one.

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

### What this is not

**It is not a security boundary.** Grants live outside the run directory, and that buys nothing
against a hostile worker: a worker holding a shell as the same user can edit the grants file
directly, and no arrangement of files on that user's disk can stop it.

Half the allowlist is not out there anyway. The bootstrap entry is read from `<run>/bootstrap`,
inside the run — so "outside the run directory" describes where grants are kept, and nothing more.

What it buys is that **no accident widens authority**. Nothing derives a grant. No command grants as
a side effect of doing something else. A run has no way to authorise itself.

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
| `unpinned` | a clause resting on nothing |

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

**A deleted introduced clause.** Every finding compares the charter against something outside it —
the detector for a gate, the pinned sha for a source, the id for the text. An introduced clause has
no outside: nothing derived it, nothing pinned it, and the charter is the only record it existed.
Delete the line and `check` reports nothing.

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
