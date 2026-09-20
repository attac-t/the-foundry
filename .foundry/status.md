# Status

What holds today, and what does not.

[Doctrine](doctrine.md) says which promises Foundry means to earn. This file says which ones it can
keep now. **Nothing here is a promise, and no promise there is quoted without this file.**

---

## The doctrine on `main` is a candidate

**Merging is not acceptance.** Nothing in `.foundry/` records the current doctrine as accepted.
Only a named person, on a dated line, can say so.

Goals carry an `Accepted:` field and three of them read *Not yet*. Doctrine has never carried one.

Until a blob is accepted, no run cites the doctrine as accepted direction, and no
identity-sensitive change proceeds from it. **Every other lane carries on.**

[#128](https://github.com/attac-t/the-foundry/issues/128) owns the goal.
[#430](https://github.com/attac-t/the-foundry/issues/430) holds the contradictions.
[#274](https://github.com/attac-t/the-foundry/issues/274) owns the other half. Nothing pins a
worker's read to a blob. So a worker cannot tell an accepted doctrine from a merged one.

---

## What Foundry runs on today

| | |
|---|---|
| autonomous work | Floor is the first adapter. **It is not the product** |
| the harness | Claude Code is today's wrapper. **It is not the mission** |
| a second harness | **one bounded passage ran**, [#738](https://github.com/attac-t/the-foundry/issues/738) — nine verbs under Codex, every one exit 0, and **not one of floor's harness reads was touched**. A passage is not the whole path |
| a machine | **Docker, through `bin/host.sh`.** One command, and the `host` gate drives it |

### The host runs work and cannot do the work

**Driven 11 September 2026**, inside the container `bin/host.sh` starts:

| | |
|---|---|
| nineteen gates, from a clone | green, on dash and mawk. Not a copy — `.git` is a directory. **Every gate this repository had that day**; six have landed since — twenty-five on 19 September — and `sh bin/gates.sh list` is the count |
| a commit | the host's author and committer, as a person who exists |
| a claim against a shared source | taken, and a second host refused |
| runs | on the machine, readable with Docker stopped |

**`sh bin/host.sh --worker` puts both providers in it**, pinned, on a second image built from the
first. `claude --version` and `codex --version` answer there as `forge`.

**A version is not a call, and calls have been made since.** On 12 September a fresh container
answered `gh api user` live and authenticated a push against the real remote, as `forge`, with the
credential coming from a Docker volume. Two adapters made real model calls through floor's own seam
on the same day.

**The plain host still carries neither.** `claude` and `codex` answer *not found* there — that image
carries `git`, `python3`, `gh` and certificates, and `--worker` is what adds the two.
[#696](https://github.com/attac-t/the-foundry/issues/696) owns that.

**Sign-ins persist where `FOUNDRY_KEYS` names a place**, and are asked every run where it does not.
The setting is described below.
[#682](https://github.com/attac-t/the-foundry/issues/682) held whether that changes, and it was
answered for this installation in writing.

### The whole path, from a machine that has only Docker

**Driven 11 September**, in a container that never saw this checkout:

```sh
git clone https://github.com/attac-t/the-foundry.git
sh bin/host.sh
  run.sh new <title>
  run.sh targets add https://github.com/attac-t/the-foundry.git main
  run.sh charter derive
  run.sh open
  run.sh gates
```

It ends `gates_exit=0`, the run reads `graded`, and its evidence carries two stamped rows — the gates
ALL GREEN and the documents AGREED, each naming the commit, the shell and the awk.

**Three refusals on the way, and each named its own cure.** A clone of the mount is not a portable
identity. A clause grading no selected target is no bar. And `HEAD` is not a ref it takes.

**Delivery is the step the default cannot reach**, because nothing is mounted and the sign-in it
needs is asked again every run.

**Configured, it reaches.** `FOUNDRY_KEYS` names a place, that place is mounted, and the sign-in
persists across containers. Two cases, and this page states both because one of them was written
here as if it were the only one.

### Sign-ins, and the three things people conflate

**Whether a sign-in persists is the owner's policy. Where it is kept is an implementation. How long
the container lives is neither.** Foundry keeps them apart.

`FOUNDRY_KEYS` is the setting. **Absent, nothing is mounted and both sign-ins are asked every run** —
that is the default everywhere.

**Its value picks the mechanism, by its own shape.** A bare name is a Docker volume. Anything with a
slash is a directory on this machine. No second setting, and no new word.

**The contract is a list of pairs** — a place a tool keeps its own sign-in, and where that place
belongs inside. A different mechanism has to satisfy that and nothing else.

| Kept | Mounted at |
|---|---|
| the forge's | `~/.config/gh` |
| the harness's | `~/.claude` |
| the judge's | `~/.codex` |

**Nothing wider.** A check refuses the whole home, because a home carries settings and a grant was
for credentials.

**Every process in the container can read all three.** They run as one user, so a suite, a plugin and
a judge share the reach. That is what this costs, and it is said here rather than found later.

**Driven 11 September**, with nothing signed in: a file written in one container was read by the next
after `--rm` destroyed the first. **The sign-ins themselves are a person's**, because every login is
interactive.

### What survives replacing it

**Driven 11 September.** One container opened a run and exited; `--rm` removed it. A second
container, started after, read the same run back.

| Survives a replacement | Where it lives |
|---|---|
| runs, and what they record | this machine's own directory, mounted in |
| a grade's log and a red gate's reason | the same, when the recipe puts them there |
| the image | rebuilt from a pinned base. **Its packages float**, so two builds can differ |
| **a sign-in, by default** | **no.** Nothing is mounted, so every store is asked again |
| **a sign-in, configured** | **yes.** `FOUNDRY_KEYS` names the place, and what it names survives the container |

**A rollback changes one number and loses no record**, because the record was never in the container.
**It does not rebuild the same image.** The base and both providers are pinned; `apt-get` is not, and
`bin/gates.Dockerfile` says so where it pins the base. Debian drops old versions within weeks, so a
pinned version is a build that breaks rather than one that repeats.

**So a rollback returns the versions somebody chose, not the bytes they had.** A judge called the
stronger claim a critical, and it was.

**The thing that does not survive is the only thing a person must re-supply.**

**It has never run on a second machine.** The two hosts proved so far are this one and a container on
its own kernel. [#299](https://github.com/attac-t/the-foundry/issues/299) owns the rest.

## What holds today

A delivery cannot silently claim it was checked against something it was not.

| Checkable with `git` and `cat` | How it fails loudly |
|---|---|
| the bar was pinned at the base | a swapped pin contradicts the record |
| every clause was held | an unheld clause is named as unheld |
| the commit exists | an absent commit is absent |
| a swap was written down | a made-up one has no record |

### Which refusals may never soften is written down, and none of it is accepted

**Floor's runner stops in a hundred and eighty places.** Until 19 September nothing said which of
those a repository could reasonably want softened, and which are fixed.

`.foundry/refusals.md` now carries one row per decision, and each says one of three things.

| | |
|---|---|
| `invariant` | 69 rows. It may never soften, and the row cites the doctrine line that fixes it |
| `default` | 98 rows. Somebody chose it once. The row names who could want otherwise, or the line a person would have to write |
| `answer` | 13 rows. It reports what a source did and refuses nothing of its own |

**`sh bin/unnamed.sh` is gate 25.** It compares the runner's exit sites to the page and refuses
either way round — a refusal with no row, or a row for a refusal the code no longer makes.

**Green there means the list is complete, never that it is correct.** The gate counts rows. Whether
any row carries the right word is beyond it, and the page says so on its own face.

**So every `invariant` row is proposed, and none is accepted.** Two models read the page across
three rounds and moved twenty-nine rows between them. **Agreement between readers is not
acceptance** — that wants a named person, in writing, dated, and nobody has given one.

#791 wants to make some of these adjustable and #792 decides where a setting may live. Both wait on
somebody accepting this list.

### A verdict is written by something that did not do the work

**True since 5 September**, and it is the one row that moved here from below.

The runner invokes the judge the charter pins, and floor consumes the receipt. No person types it.

Proved unattended, end to end. **The judge said *revise*, so floor refused rather than passing:**
`judged clauses no judge approved: 1`, exit 39. Where the harness is absent it records
`unavailable`, asks nothing else, and never falls back. PR #506, floor 0.69.0.

**Two things this does not say.** Nothing counts rounds, so an exhausted budget is recordable and
still undetectable. And one harness, once, is not two: RFC-001 wants a second and this is the first.

**The second one ships now, and a panel of two has run.** On 12 September a single clause carried
`codex:adversary` and `anthropic:adversary`, on one candidate. Codex answered `revise` and
anthropic answered `reject`, each in its own receipt, from its own brief. `complete` and `deliver`
both returned 15, naming both members.

**So a refusal from either blocks delivery, and that is now driven rather than argued.** Two cases
in floor's suite hold it: a panel of two that agrees, and a panel of two where one refuses.

**What is still one is the harness Foundry runs on.** Two judges are two vendors; the thing that
runs the work is not. Floor's core reads one harness in thirteen places, and #711 owns that.

**The decision is written and it is not an adapter.** *Neither yet, and explicitly not an
exemption list* — the owner's words, 15 September 2026. An adapter derived from one harness would
encode that harness behind an abstraction, and an exemption list writes down thirteen allowances
nothing ever removes. **[#738](https://github.com/attac-t/the-foundry/issues/738) is the successor**:
one bounded passage with Codex as the harness, never as a judge. The passage comes first and the
adapter is extracted from what it needed.

**A panel of two also broke something.** A brief and a receipt were named for their clause alone, so
the second member's landed on the first's. The member names the file now, and the ledger's digest
points at a file that is still there.

**The adapter is shipped and tested now.** It was run by no test when the line above was written.
#511 gave it one, and #516 moved it under `plugins/floor/adapters/`, where Foundry owns it. Eleven
checks drive the real script, and thirteen mutants each die on a different one. Floor 0.71.0.

**A repository names the adapter it trusts, and the digest it trusts it at.** `.foundry/judged`
carries `reach`, and `@adapter <id> <digest>` resolves only under the plugin. Never `PATH`, never
*latest*. A pin that is not a digest refuses at derive, so nobody authorises a bar nothing could
meet. A shipped adapter this host lacks refuses at 21, and content the pin does not name refuses
at 40.

A gate named `judged` holds this repository's own declaration to that rule. It goes red on a
drifted pin. Red too on an adapter this tree does not ship, and on a declaration naming none.

**A repository onboarded before the adapter has a route now.** `adopt.sh` writes the reach and
pins the digest; `adopt.sh upgrade` moves the pin when floor ships new content and prints both. It
writes a working tree change and nothing else — a person still reads the diff and commits.

**`join.sh` reports judges now, and refuses without one.** It counts what `.foundry/judged` names.
A file naming no judge stops the join, and prints the remedy. It also reports the skills the rules
name, and the plugins this host loaded.

**This page said the opposite until 8 September**, and said no issue owned it.
[#573](https://github.com/attac-t/the-foundry/issues/573) owned it the whole time.
[#593](https://github.com/attac-t/the-foundry/pull/593) closed ten of its eleven boxes. Floor 0.75.0.

**The exit code was settled, not left open.** [#573](https://github.com/attac-t/the-foundry/issues/573)
closed 9 September with all eleven boxes. Three absences refuse — gates, judges and grants. **The
other three still print and stop nothing, by decision.** A tree missing none of the three exits 0
and gains no new line.

And nothing says what a capability expects a repository to own - #519. So nothing can stop work that
crosses that line - #520. And nothing reports the gap without naming where it was found - #521.

**Every path to a lower bar runs through a visible, dated commit.** That holds for the supported
workflow, with history intact and no hostile hand. It is not a wall — see below.

*Silently* means the record does not fight itself, and history shows the act. It does not mean the
act cannot be done.

## What does not hold yet

Each line names the issue that would close it. **None of them is claimed anywhere.**

**Two of them named merged work, and merged work is not an owner.** A reader who followed either
link found a closed page and read the gap as handled. `#343` shipped the guard that *refuses* a
person here; `#359` measured that the identity is an admin and the provider refuses nothing.
Both are true, both are done, and neither closes the line above it.

**And one said nobody owned it while the board's own measure did.** *End-to-end work runs without a
hand at some step* read `none yet` here. #736 has owned exactly that claim, as a number — issues
completing the whole path with no operator commands, currently zero against a threshold of one.
**A row saying nobody owns a gap sends the next reader to file a synonym**, which is the opposite of
what this table is for. Three rows below still say it, and each of those is true.

| Not true today | Owner |
|---|---|
| a worker reads the doctrine pinned at its base | [#274](https://github.com/attac-t/the-foundry/issues/274) |
| the suite that ran was the suite pinned | [#341](https://github.com/attac-t/the-foundry/issues/341) |
| who said yes is more than the run's word | [#156](https://github.com/attac-t/the-foundry/issues/156) |
| a person can answer a judged clause | **none yet.** [#343](https://github.com/attac-t/the-foundry/pull/343) is merged and refuses one |
| acceptance can be withheld | **none yet.** [#359](https://github.com/attac-t/the-foundry/pull/359) is merged and only measured it |
| the record outlives the run directory | [#337](https://github.com/attac-t/the-foundry/issues/337) closed 9 September, six of six. **It asked whether a reader who was not there catches a forged record, which is not this row.** Nothing named owns the row today |
| a question reaches a person and comes back | none yet |
| end-to-end work runs without a hand at some step | [#736](https://github.com/attac-t/the-foundry/issues/736) |
| the same core path works through a second harness | [#738](https://github.com/attac-t/the-foundry/issues/738) |
| a repository brings its own opinion | [#519](https://github.com/attac-t/the-foundry/issues/519) |

**Two principles landed on 19 September and only one of them is checked.** *The core names no host
and no vendor* holds, and `hosts`, `judges` and `providers` read it — one for what Foundry runs on
and two for what answers it. *A repository brings its own opinion* does not, and it
had no row here until today — a reader of the doctrine alone would have taken it for a fact.

**What it would take.** A capability states what it expects a repository to own, and #519 holds four
boxes for that, none ticked. Nothing can say what a setting is or where it came from, which is #791
at none of six.

## How far each promise has got

Doctrine names five people and a promise to each. **None holds in full.**

| The promise | Where it has got to | What would say it broke |
|---|---|---|
| a founder's business claims are listed and dispositioned | not built. A result names constraints in prose, and nothing lists them | **nothing can.** A limit nobody wrote down leaves no trace to miss |
| a domain expert's outcome, limit and exception are each accounted for | not built | one they stated is absent from the account, or is closed without being answered |
| a user-facing change declares its design impact | not built | **nothing can.** A change that declared nothing produces no record to read |
| the seams, rules, evidence and doubt are named | partly. A run records evidence and doubt. It does not name seams | a run touched a seam its own record does not name |
| public surface, compatibility and developer experience are stated | not built | a delivery changed the public surface and the record is silent about it |

**Two of the five cannot break loudly, and that is a gap rather than a caveat.** Both turn on an
absence: a constraint nobody captured, and a change that declared nothing. **Absence leaves no
record**, so each reads clean at the moment it has failed. The other three can be checked against
what a run wrote down.

**Agree the goals. We'll do the work. We'll ask when we need you** rests on all five, plus a
question reaching a person and coming back. It does not hold today.

## This is not a security boundary

**A hostile hand on the same shell defeats every wall here.** Foundry catches accident, drift and the
easy path.

No sentence in any Foundry file may imply otherwise.

## A line the owner has not settled

The doctrine this replaced carried one destination sentence. **The current doctrine does not state
it**, and whether it is still the vision is the owner's to settle — it is an open question, not a
claim:

> However fast change is produced, every delivery carries proof the owner keeps: this exact commit
> met a bar its producer could not lower.

Were it stated today, four of its claims would be false. Three are the phrases *proof*, *could not
lower* and *the owner keeps*. The fourth is *this exact commit met a bar*, which the pinned-suite gap
and the run-directory gap leave unproved. The rows above own each one.
