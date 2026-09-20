# Swimlane: Examples

One drawing, worked through. It is Foundry's own path. A drawing of the thing you stand in is the
one you can check.

---

## How does a request become a merged change?

That is the scenario. Not *the system*. It has a start, an end, and a question a reader can answer.

```
  PERSON              WORK SOURCE            RUN                 BAR
  what good means     the item               the doing           the judging
────────────────────────────────────────────────────────────────────────────────
  write an item
  and its list
       │
       ├─── an outcome, ──▶ item opened
       │    and how to           │
       │    know it              │
       │                         │
       │                    read at a base ──▶ charter derived
       │                         │              (clauses pinned)
       │                         │                   │
       │                    standing grants ╌╌▶ may grade,
       │                    (.foundry/practice)  may deliver
       │                                             │
       │                                        work, commit ────▶ every gate
       │                                             │              runs
       │                                             │                │
       │                                        evidence  ◀╌╌╌╌╌╌╌╌╌╌─┘
       │                                        (what passed,
       │                                         what did not)
       │                                             │
       │                    delivery ◀───── a brief, and
       │                    opened            the item it answers
       │                         │
       │                         │
  read the brief ◀───────────────┤
  and the diff                   │
       │                         │
       ├─── merge ──────────────▶│
       │    (the change lands)   │
       │                         │
       └─── tick the boxes ─────▶ item closed
            (a person reads
             the list)
```

## What the drawing shows that a flow could not

**The bar never reaches the person.** Every arrow out of `BAR` lands in `RUN`. A person who wants to
know what was checked reads the run's own account of it. That gap is why a brief carries the
evidence rather than pointing at it.

**Two arrows leave `PERSON` at the end, not one, and neither is acceptance.** Merging lands the
change. Ticking the boxes says the item's own list was met. A merge that skips the second closes an
issue nobody checked.

**A merge is not a yes.** It moves the work into the trunk. Whether the outcome was wanted is a
separate act, recorded separately, by a named person. Drawing merge as acceptance is how a run comes
to look like it accepted its own work.

**`RUN` never writes into its own lane's authority.** Grants cross from `WORK SOURCE` as information,
never as a request the run can make of itself.

## Reading the two arrows

```
──▶   a request, a work item, a decision, a delivery
╌╌▶   information, an observation, evidence
```

`standing grants` and `evidence` are dashed. Neither one lets anybody decide anything. They tell a
lane what is true, and the lane still acts on its own account.

`merge` is solid because work crosses on it. **No arrow here carries authority**, and none of them
records a yes.

## Swap the work source

Replace `WORK SOURCE` with a directory of files. **Nothing else in the drawing moves.** The item is still read at a base. Grants still cross as
information, and the delivery still lands where a person reads it.

If a redraw were needed, the drawing would have been of GitHub, not of Foundry.

## What a reader who was not there can say

| Question | From the drawing |
|---|---|
| who acts at each step? | four lanes, and every action sits in one |
| who decides? | the person. Merging is not one of the two |
| what crosses each boundary? | every arrow is labelled. None is bare |
| where does a person get stuck? | at the brief, because the bar never speaks to them |

**If a reader cannot answer all four, the drawing failed.** Adding boxes will not fix it.

---

## How does a chef get tomorrow's order?

**The deciding lane is a person who does not read code.** The first drawing's person writes items
and reads diffs. Every lane in it is one an engineer already lives in. So it proves nothing about
the boundary this skill exists to expose.

Scenario: a shift's order is proposed and the chef settles what only the chef can.
Starts: tomorrow's covers are known. Ends: the order is placed.

```
  CHEF                  KITCHEN              SUPPLY              THE APP
  menu intent           what is on hand      lead times          the proposing
  and shift trade-offs  and what it yields   and what is short
────────────────────────────────────────────────────────────────────────────────
  tomorrow's covers
  and the prep plan
       │
       ├── covers, menu, ─────────────────────────────────────▶ read
       │   prep plan                                              │
       │                                                          │
       │                  stock, par levels, ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌▶ │
       │                  yields, waste                           │
       │                        │                                 │
       │                        │           lead times, ╌╌╌╌╌╌╌╌▶ │
       │                        │           what is short         │
       │                        │                                 │
       │                        │                            a draft order
       │                        │                            and the two
       │                        │                            exceptions
       │                        │                                 │
  the fish is ◀────────────────────────────────────────────── ask
  two days out                                                    │
       │                                                          │
       ├── serve it Thursday ────────────────────────────────────▶ │
       │   instead                                                 │
       │                                                      the rest of
       │                                                      the order
       │                                                      stands
       │                                                          │
       │                        │           order placed ◀─────────┤
       │                        │                 │                │
       │                  delivered, ╌╌╌╌╌╌╌╌╌╌╌╌─┘                │
       │                  short by one crate                       │
       │                        │                                  │
  read what came ◀──────────────┴──────────────────────────────────┘
  against what was asked
```

## What the chef owns, and what never reaches them

**One trade-off, named.** The fish is two days out and Thursday's menu wants it. Serve it Thursday,
or substitute. **That is a menu decision**, and nobody else may take it.

**Two exceptions, not the whole order.** Everything the app can settle from stock, yields and lead
times is settled. The chef meets what is left.

**What never crosses into the chef's lane:** a schema, an API, a host, how the app checked itself.
Those are not the chef's. A lane carrying them would be the app asking a cook to grade software.

**The rest of the order does not wait.** One arrow leaves the chef and the draft continues. A
drawing where every line stops at the human is a drawing of a bottleneck.

**Evidence comes back and nothing decides on it.** *Delivered, short by one crate* is dashed. It
tells the chef what happened and changes no order. Tomorrow's plan is a fresh decision.

## The counterexamples this refuses

| Instead of | It would say |
|---|---|
| a lane called `PREP` | that is a stage. `craft-flow` draws stages |
| a box reading *chef approves* | which trade-off? A generic approval names no claim |
| an unlabelled arrow to `SUPPLY` | the systems interact somehow. Refuse it |
| a lane for the ordering service's vendor | an adapter at the edge, unless the adapter is the scenario |

## What a reader who was not there can say

| Question | From the drawing |
|---|---|
| who decides? | the chef, and only about the menu |
| what exactly? | serve the fish Thursday, or substitute |
| what continues without them? | the rest of the order |
| what comes back? | what arrived, against what was asked |

**The chef never sees a bar, a gate or a verdict.** That absence is the finding. It is the case the
doctrine's five people are about: owning an outcome you cannot check.
