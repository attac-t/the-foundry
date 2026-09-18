# Doctrine

Goals live in [`goals.md`](goals.md), authority in [`authority.md`](authority.md), what holds today
in [`status.md`](status.md). Architecture and daily practice keep their own records.

---

## What Foundry is

> **An open, composable protocol for continuous software improvement.**

A shared way of carrying direction, work, evidence, delivery and learning across workers that can
be swapped out. Foundry installs on a repository and uses its knowledge, tools, tests and rules.

| Word | Means here |
|---|---|
| open | inspectable, and buildable again without depending on one vendor |
| composable | each capability is useful alone, and they join or swap through stated contracts |
| continuous | improvement keeps going, and a run may work unattended. **Never outside the authority it was given** |
| claim | one statement somebody is answerable for, together with the person entitled to decide it. Never a file, a role, or a worker's inference |
| worker | whoever does the work — a person, a model, a harness. Replaceable by design, and never the authority |
| **forge** | the replaceable boundary through which work is listed and proposed. **An adapter, never the protocol** |

**This is identity, not mission.** Identity says what kind of thing Foundry is; mission says why it
matters. Keeping them apart stops a mechanism being taken for the reason.

## Mission

> **Let software keep improving while people decide what good means.**

Producing change is becoming cheap. Keeping it true to human purpose, standards and consequence
stays hard. **That gap is why Foundry exists**, and it grows as machines build more.

## Philosophy

**A belief must help decide a question nobody has asked yet.** A sentence describing today's code
is not one.

| Belief | What it decides |
|---|---|
| software should grow with the people it serves | whether change is a cost to contain or the point |
| software exists to serve people | who picks the purpose, when a machine could pick one |
| human judgement is scarce; computation is abundant | where a person's attention goes |
| workers change; direction should endure | what must be written down, and what may die with a session |
| truth includes uncertainty | whether a doubt is reported or smoothed away |
| complexity must earn its place | whether a new role, service or abstraction is added at all |

## The core refusal

> **Authority attaches to a claim, never to a file, a title or a keyboard. It changes only under the
> authority already in force. Producing, merging and staying silent confer none.**

The one line Foundry will not trade. [`authority.md`](authority.md) carries it out.

## The people we serve

Anyone answerable for a software outcome, not only the people who write code.

**None holds until [`status.md`](status.md) says it holds.** That file, never this one, says how
far each has got.

| Person | The promise | What the work hands back must say |
|---|---|---|
| a founder | purpose, business limits and costly trade-offs stay visible | it lists each business claim you own as held, changed, unresolved, or yours to decide |
| a domain expert, such as a chef | your outcome, limit and exception keep their meaning in ordinary words | each one you stated is accounted for, and an unresolved one stays unresolved |
| a designer | experience intent is an input to accept, not a late opinion | every user-facing change declares its design impact, and cites a rule or names the decision it needs |
| an application engineer | the repository's architecture, standards and evidence travel with the work | it names the seams it touched, the rules it used, and what is still in doubt |
| a framework engineer | consumer contracts and developer experience are outcomes, not polish | it states what happened to the public surface, to compatibility, and to developer experience |

**Two of these five checks cannot be run, and that is a gap rather than a caveat.** The founder
cannot see a business limit nobody wrote down, and the designer cannot see a change that declared
nothing. **Absence leaves no record**, so both checks read clean at the moment they have failed.
The other three answer from what the work hands back, and that record exists.

**A lens is not authority.** Who decides which claim comes from the repository's own map, in
[`authority.md`](authority.md). Five kinds of judgement, never five ranks.

## The promise

> **Agree the goals. We'll do the work. We'll ask when we need you.**

**The worker says this.** Everywhere else here, *we* is the people who wrote this file.

**It holds when [`status.md`](status.md) says it holds.** What it means: with accepted goals and
named authorities, Foundry carries routine work forward and returns consequential decisions
to the people entitled to make them.

Your expertise guides the work without making you its operator, and **the worker cannot quietly
become the authority.**

## What Foundry does not promise

Enduring lines, not today's gaps — [`status.md`](status.md) holds those.

- perfect software
- that a check captures good
- that evidence replaces judgement
- that every user decides every claim
- merge or deploy by default
- that every repository runs unattended
- one model, vendor, harness, **forge** or plugin forever
- learning that rewrites purpose
- purpose, missing domain truth, or every consequential claim found. **Foundry carries what people
  state. It cannot supply what nobody said**

## Principles

What must stay true while we chase the mission. **Each refuses something**, and the refusal is the
test of whether it earns its place.

| Principle | What it refuses |
|---|---|
| **Human direction comes before work.** Every repository says why it exists, who it serves, and what it is reaching for | invented goals, an identity read off the backlog, activity with no intended result |
| **Authority is specific.** Whoever decides a product trade-off may not decide a design, security or engineering one | the single owner, one person quietly absorbing every trade-off |
| **Producing work grants no authority over it.** A worker may inspect, ask, challenge, plan, build, test, explain and propose on its own authority. That is the whole list | self-approval, a rule changed mid-run, a worker rewriting its own definition of done |
| **Automate mechanics; escalate meaning.** Foundry never invents a costly trade-off because nobody stated one. It asks | approval theatre, stripping out the calls only people can rightly make |
| **Direction and evidence outlive replaceable workers.** Anything durable is written where anyone can read it | lock-in, session memory treated as truth, a worker's identity baked into the design |
| **Evidence supports judgement; it does not replace it.** A check that failed or never ran never quietly becomes a pass | green means good, unknown read as pass, a record claiming more than a reader can check |
| **Compose with the repository.** Use its purpose, knowledge, tools and habits before inventing substitutes | pasting Foundry's direction into a target, replacing local knowledge that works |
| **Learn without silently changing direction.** A worker may propose a change to doctrine, goals or rules. It reaches later work only once the right people accept it | authority that amends itself, a lesson promoting itself into a rule |
| **Prefer the smallest system that solves the observed problem.** Convention before configuration; a file before a service | machinery for a problem nobody has had, a permanent org chart of agents |

## What is durable

The principle above says **anything durable is written where anyone can read it.** This says which
things those are.

**Durable is not shared meaning.** What survives a swap of the machinery is one question. What two
copies of Foundry must both mean by a word is another. **This list answers the first and not the
second**, and it binds no consumer.

**Replace every worker, host, model, tracker and delivery mechanism. These survive:**

| Kind | Written by | What a reader can still check |
|---|---|---|
| a **goal** | people | what someone is reaching for, and who said so |
| a **doctrine** | people | what must stay true, and what each part refuses |
| a **clause** | people | one requirement, and what would show it met |
| a **pin** | machinery | the exact content a clause was judged against |
| a **receipt** | machinery | that a named judge was asked, and answered |
| a **ledger row** | machinery | what happened, in the order it happened |
| a **run record** | machinery | that work began, what it claimed, and what it proved |

**The two halves are durable for different reasons.** Direction is durable because people decided it
and may be held to it. Evidence is durable because machinery wrote down what it did. Losing either
loses a different thing, so the column says which.

**A run means its record, never a run in flight.** The record outlives the machine. The process, the
workspace and a worker's memory do not, and nothing here promises they will.

### What is not durable

**Authority is not on this list.** A record may say a named person granted something, dated. It
never confers the right. [`authority.md`](authority.md) holds that line, and this does not restate
it.

**Everything above the record may be swapped freely.** The harness, the model, the resolver, the
judge, the host, the plugins. This repository's own gates, suites and runner sit there too. Swap any
of them and every row above still reads the same.

**Naming only one half would read as naming both**, so both halves are named.

### How a kind joins

**A revision closes. The ontology does not.** Each published revision of this list is finite and
complete for itself. A seventh kind is a decision, never a breach — a closed list would make
tomorrow's valid seam a violation.

**The gate is doctrine approval by the named human authority.** A panel advises and never admits. An
open list with no admitter moves the authority it removed onto its own gate.

**A candidate must pass one test.** Replace every worker, host, model, tracker and delivery
mechanism, then ask whether a reader can still check the thing. If the answer depends on which
machinery ran, it is a choice and not a kind. **A fourth seam in this repository is tested against
that sentence.**

**Each published revision carries an identifier, because adoption names one.** A revision freezes
when the authority above approves it. **No pinning machinery exists here** — nothing today can hold
a consumer to a named revision, and this page does not pretend otherwise.

## Vision

**Not a promise.**

Software is never trapped at the moment it was built. It keeps fitting the people it serves as they,
their knowledge and their tools change — **and none of them has to become an engineer to keep it
fitting.**

The best intelligence available does more of the work. People spend their attention on purpose,
judgement and consequence. Any worker can be swapped out, and the direction and the memory stay.

**More people get to shape software that fits their lives.** Autonomy grows human agency, instead of
gathering control into the tools that supply it.

## Strategy

Our current bets. They change as evidence changes, and **never quietly rewrite the philosophy, the
mission or the principles.** A bet is not authorised work — [`goals.md`](goals.md) is where an
outcome becomes something to do.

A bet with no way to lose is a belief in the wrong section.

| The bet | Dies if |
|---|---|
| start where good is already exact | nobody there writes a bar we can pin, or they would rather have a coding agent and an ordinary review |
| use Foundry on Foundry, every day | the loop makes output without moving a goal, or it needs rescuing by its authors |
| earn autonomy in honest layers | a person cannot tell which layer they are on, or a weaker one causes harm its language implied it prevented |
| prove the protocol away from home | a second harness needs a fork, a hand at every step, or the core behaviour written twice |
| make the ordinary path the product | a first useful proposal means learning internal verbs or wiring plugins by hand |
| broaden who takes part, without widening authority | a non-engineer needs a translator, or their input becomes a vague say over everything |
| turn outcomes into learning | a measured outcome rewrites a goal by itself, or no later decision changes after one is seen |

## Goals

[`goals.md`](goals.md) is the only source, and each goal has its own record.

**Every durable goal traces to the mission and to a current bet.** Missing either one, it is
ungrounded.

## Foundry, and the repositories it improves

Two kinds of direction. The target says what its software is for and what good means there.
Foundry says how a worker stays directed and honest while helping it change.

**A target answers in its own words and its own forms.** Foundry helps its people write them, never
writes them for them, and never asks a repository to copy Foundry's documents.

**The target has the last word on what its software means.** Foundry keeps the last word on whether
it takes part: it will not invent authority, dress doubt as success, or make evidence say more than
it shows. Where that is the clash, it stops and asks.

---

Accepted: Not yet. **Merging landed this page; it accepted nothing.**
[`status.md`](status.md) has said so since the day it merged. This line says it here, where a reader
of the doctrine meets it.
