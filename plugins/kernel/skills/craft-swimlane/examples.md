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
