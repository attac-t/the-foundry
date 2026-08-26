# Doctrine

Foundry's first read. What it is, why it exists, what it believes, and where it is going.

**A run reads this and never writes it.** Anyone may propose a change. Only a human accepts one, and
a run that proposes a change gains nothing from it. Later work starts from what was accepted.

This is not a manual, an architecture record, a list of today's gaps, or a history. Those have their
own homes: [`authority.md`](authority.md) holds who decides what, and [`status.md`](status.md) holds
what is true today.

---

## What Foundry is

> **An open, composable protocol for continuous software improvement.**

A protocol is a shared way of working. Foundry gives people and replaceable workers one path from
direction to work, to evidence, to delivery, to learning. It installs on a repository and uses that
repository's own knowledge, tools, tests and rules.

Foundry is larger than any model, agent, harness or plugin. Every part is useful alone and stronger
with the rest. Floor is the first adapter for autonomous work. It is not the product.

## Philosophy

What we believe about people, software and truth. Each belief has to help decide a question nobody
has asked yet. A sentence that only describes today's code is not a belief.

### Software should grow with the people it serves

Needs, knowledge and circumstances change. Useful software should change with them, rather than stay
trapped at the moment it was built.

### Software exists to serve people

More capable software does not get to pick its own purpose. People decide what good means, which
trade-offs are allowed, and which consequences matter.

### Human judgement is scarce; computation is abundant

People should spend attention on purpose, lived context, hard trade-offs and consequence. Machines
should carry as much of the rest as they safely can.

### Workers change; direction should endure

Models, tools, vendors and sessions come and go. Purpose, decisions, evidence and learning must
outlive them.

### Truth includes uncertainty

A clear *we do not know* beats a confident guess. Progress that hides doubt is not progress.

### Complexity must earn its place

Every new process, role, service and abstraction bills the future. Foundry adds machinery only when
a real failure shows why it is needed.

## Mission

> **Let software keep improving while people decide what good means.**

Producing change is becoming cheap. Keeping that change true to human purpose, standards and
consequence stays hard. That gap is why Foundry exists.

## The people we serve

Foundry serves anyone answerable for a software outcome, not only the people who write code.

| Who | What they protect |
|---|---|
| a founder | the product's purpose, its business limits, and what it costs to get them wrong |
| a domain expert, such as a chef | the truth of the work the software has to support |
| a designer | the experience and the behaviour people meet |
| an application engineer | whether the system stays coherent, sound and operable |
| a framework engineer | public contracts, compatibility, and how the thing feels to build on |

**These are scopes, never a ranking.** One person may hold several. A team may split them. Nobody
earns the right to decide every kind of claim by being an administrator, or by doing the work.

## The promises we must earn

Commitments, not a claim that every part exists. [`status.md`](status.md) says which ones hold today
and where the edge is.

### Your direction survives the worker

Purpose, standards, decisions and goals stay readable when a session ends. They also stay readable
when a model, harness, plugin or vendor changes.

### Your expertise can shape the work

You state the outcome, limit or trade-off you answer for, in plain words. You do not have to become
an engineer, or an agent's operator, first.

### Your attention goes where it is needed

Foundry handles routine steps under rules people already accepted. It asks a person when meaning,
authority, risk or consequence genuinely changes.

### You can understand what happened

Every proposed change is clear to someone who did not watch it happen. It says six things:

| | |
|---|---|
| intent | what it meant to do |
| result | what it actually did |
| evidence | what was checked, and what came back |
| assumptions | what it took for granted |
| uncertainty | what is still unknown |
| next | what a person has to decide |

### You can replace the machinery

No worker, model, harness, plugin, host or vendor holds the only useful copy of the direction, the
work, or the evidence.

### The worker does not quietly rewrite the deal

Doing the work grants no right to approve it, and none to lower the bar. Direction a worker proposes
never applies to the work already under way.

## Principles

What has to stay true while we chase the mission. Each one refuses something.

### 1. Human direction comes before work

Every repository says why it exists, who it serves, and what must stay true. It also says what it is
trying to reach, and how it plans to get there. **Work that advances no stated goal shows up as
ungrounded.**

*Refuses: invented goals, a product identity read off the backlog, activity with no intended result.*

### 2. Authority is specific

Whoever decides a product trade-off may not be whoever decides a design, security, operational or
engineering one. Each repository says who decides which kind of claim, how a clash is settled, and
how that arrangement changes.

*Refuses: the single owner, the administrator who decides everything, one person quietly absorbing
every trade-off.*

### 3. Producing work grants no authority over it

A worker may inspect, ask, challenge, plan, build, test, explain and propose. **It never gains the
right to approve its own work, or to change the rules that judge it.**

*Refuses: self-approval, a rule changed mid-run, a worker rewriting its own definition of done.*

### 4. Automate mechanics; escalate meaning and consequence

Foundry removes ceremony. It does not remove the decisions that give work its purpose, or that make
a costly trade-off legitimate.

*Refuses: approval theatre, and stripping out the calls only people can rightly make.*

### 5. Direction and evidence outlive replaceable workers

Anything durable belongs in an open form anyone can read, tied to the repository and the work.
Sessions are temporary. Providers and mechanisms are swappable.

*Refuses: lock-in, session memory treated as truth, a worker's identity baked into the design.*

### 6. Evidence supports judgement; it does not replace it

Foundry names the exact change it looked at, the rules it used, and the checks it ran. It also names
what came back and what is still open. **A check that failed or never ran never quietly becomes a
pass.**

*Refuses: green means good, unknown read as pass, a record claiming more than a reader can check.*

### 7. Compose with the repository

The repository brings its own purpose, knowledge, people, tools, tests and habits. Foundry uses them
before inventing substitutes.

*Refuses: pasting Foundry's own direction into a target, and replacing local knowledge that works
with a generic stack.*

### 8. Learn without silently changing direction

Outcomes should improve later work. A worker may propose a change to doctrine, strategy, goals or
standing rules. **That proposal reaches later work only after the right people accept it.**

*Refuses: authority that amends itself, and a lesson promoting itself into a rule.*

### 9. Prefer the smallest system that solves the observed problem

Convention before configuration. A file before a service, while a file is enough. New machinery has
to name the failure that earned it, and the test that would let it go.

*Refuses: machinery built for a problem nobody has had, and a permanent org chart of agents.*

## Vision

Not a promise. Where this is going.

Software is never trapped at the moment it was built. It keeps fitting the people it serves as they,
their knowledge, and their tools change.

A founder grows a product without becoming an engineering manager. A chef improves the software
behind a shift without learning a software process. A designer protects an experience without
watching every pixel. An engineer chases coherence, compatibility and a good build without policing
every generated line.

The best intelligence available does more of the work. People spend their attention on purpose,
judgement and consequence. Any worker can be swapped out. The direction and the memory stay.

Every improvement can say what it meant to achieve, what changed, what was learned, and what is
still unknown.

**More people get to shape software that fits their lives.** Autonomy grows human agency, instead of
gathering control into the tools that supply it.

## Strategy

Our current bets. They change as evidence changes, and **they never quietly rewrite the philosophy,
the mission or the principles.**

### Start where good is already exact

Begin with framework authors and engineering teams who protect public contracts, compatibility,
quality and developer experience. Their standard is already written down, their change volume is
high, and incoherent work hurts them fast.

A starting market, never the limit. Use it to build the rigour a founder, a designer and a domain
expert will need later.

### Use Foundry on Foundry, every day

The daily loop starts from this document and the current goals. It picks useful work, makes a
proposal a person can read, tests what it did, and leaves something for the next session. **Activity
that advances no goal is a defect in the loop.**

### Earn autonomy in honest layers

First a safe proposal a person can read, under human direction. Then stronger evidence, more
independent judgement, an outcome easier to check. **Never sell a later layer as though it shipped.**

### Prove the protocol away from home

Run Foundry through a second harness, on a repository that is not this one, for someone who did not
build it. Prove a capability ships alone, and that swapping the machinery erases neither direction
nor evidence.

### Make the ordinary path the product

A new person can install Foundry and give a repository its own direction. They can start a run, see
where it is, recover when it breaks, and get a proposal. **None of that should need Foundry's
private vocabulary.**

### Broaden who takes part, without widening authority by accident

Let founders, designers and domain experts state the claims they are qualified to decide, and make
those claims usable by a worker. Keep a cross-domain trade-off out in the open, rather than handing
one role quiet control.

### Turn outcomes into learning

Watch whether delivered work changed what it meant to change. Use that to propose better goals,
rules and bets. **People accept a change to direction. A worker never promotes its own lesson.**

## Current goals

What this strategy has to produce next. These change more often than the mission or the principles.

### 1. Ground every fresh session

A worker holding only the repository and its accepted base can state six things: the mission, the
people, the promises, the principles, the current bets and the goals. Before starting, it says which
goal the work advances and which principle limits it.

### 2. Run a useful daily loop

Foundry improves itself daily without inventing work to look busy. It carries on through routine
steps and stops for real decisions. It leaves either a clear proposal, or one honest reason nothing
useful could proceed.

### 3. Give a new repository an honest first path

A person installs Foundry on an ordinary repository. They write and accept that repository's own
direction, set a first goal, and get back an unmerged proposal. **None of it needs the internals
assembled by hand.**

### 4. Prove portability and composition

The same core path works through a second harness and on a repository somebody else maintains. Every
major capability stays useful without the rest.

### 5. Make every result legible

A cold reader can say what a proposal tried to improve and what changed. They can also point at the
evidence, the uncertain claims, the next decision, and the goal it serves.

### 6. Let non-engineering expertise in

A founder, designer or domain expert states one scoped outcome in their own words. A worker uses it
without bending the meaning, and they can read the result without learning our jargon.

### 7. Close the learning loop

Foundry watches an outcome after delivery, compares it with what was intended, and carries the
lesson into a later proposal. **It never changes accepted direction in the run that proposes the
change.**

## How this governs the work

Every fresh worker reads the accepted version of this file before it picks, plans, does or judges
anything.

Every durable goal traces back to the mission and the current bets. A proposed change names the goal
it advances and the principles that limit it.

**Anyone may challenge this file.** A worker's edit is only ever a proposal. It applies once a person
with the right authority accepts it, and later work starts from that.

Architecture, current status, operating rules and work history live in their own files. They may
carry out this one, or test it. They never replace it.

## Foundry, and the repositories it improves

Two kinds of direction, and they must never be confused.

This file says what Foundry should become and how Foundry must behave. **Each target repository
brings its own philosophy, mission, principles, vision, strategy and goals** for the software living
there.

| Whose call | What it covers |
|---|---|
| the target repository | what its software is for, and what good means there |
| Foundry | how a worker stays directed and honest while helping it change |

The target owns its meaning, and Foundry cannot overwrite it. The target also cannot make Foundry
invent authority, dress doubt as success, or make evidence say more than it shows. Where the two
truly clash, **Foundry stops and asks the people entitled to settle it.**

> **Foundry brings the method. The repository brings the destination.**
