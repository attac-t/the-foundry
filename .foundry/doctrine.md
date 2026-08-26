# Doctrine

Why Foundry exists, who may say what good means here, and what is not true yet.

**A run reads this and never writes it.** A human said yes to every line, at a commit, on an issue
anyone can open. A change here counts for nothing until a human commits it and a later run reads it.

---

## Mission

> **Every change must answer to the people who signed off its bar.**

The short form:

> **Every change answers to a bar its producer did not sign off.**

**Did not, never could not.** *Could not* is a promise this cannot keep. A producer on the same shell
can edit any file here, and v1 does not close that. What does hold is smaller, and it is set out
below.

## Principles

|                                 |                                                                                                     |
| ------------------------------- | --------------------------------------------------------------------------------------------------- |
| the producer never owns the bar | it can ask for one. It is never the hand whose commit makes one count                               |
| a record informs, never grants  | who may say yes is read from history, never written by the run that needs it                        |
| only a human decides meaning    | a machine may grade, draft, ask and refuse. It may not say what good is                             |
| every part ships alone          | a plugin that needs another to be useful is one plugin wearing two names                            |
| say what is not true            | an unchecked claim, a left-over risk and a known gap each get a line, and the line says which it is |

## Authority

**The boundary is the claim, not the file.** A repository has as many authorities as kinds of claim.
One person may hold every one. That is a small map, not a different model.

| Term           | Means                                                                        |
| -------------- | ---------------------------------------------------------------------------- |
| producer       | proposes or performs the change. A role per change, never a kind of person   |
| authority      | who may say yes to a claim. Named by the map, for the claim's pinned source  |
| decision-maker | the named authority for one trade-off, recorded inside that decision         |
| acceptor       | who accepts a delivery. Today it cannot be withheld, and it is self-reported |
| accountability | who answers for a result. Traced, never granted, and never authority         |
| ownership      | never used bare. Repository, product and IP are three facts, not one         |

### The map

One map per repo Foundry runs on. It says which claims answer to which people.

> **A map states how it changes, or it is not a map.**

Signed off on [#128](https://github.com/attac-t/the-foundry/issues/128), 25 August 2026. Without that
rule, whoever installs it quietly owns the lot. That is the model thrown out here.

| Repository | Its map                                                             |
| ---------- | ------------------------------------------------------------------- |
| one person | one generated line. Convention first, so nothing is written by hand |
| a team     | claim authorities and conflict rules, written out                   |

**A map change is signed off under the rule already in force. It counts for later runs only.** A map that
changed under its own new rule could rewrite its own authority in a single commit.

### Six rules

1. The pinned source picks the row. The map names the human.
2. A change answers only to what was signed off at or before its base. Its own writes count for
   nothing.
3. A yes is written down. It is dated and it names who said it. Silence and merge are never a yes.
4. A real clash goes to a written order of rank. With none, that trade stops until both sides say
   yes together. Only that trade stops. Other work carries on.
5. Anyone can ask for a map change. Only the change row says yes to it.
6. Point at it, never make it. Nothing a producer writes can make authority, a yes or a verdict.

**A named human in a map is a record, not a control.** Foundry does not claim to know who wrote a
line. It will not claim that until [#156](https://github.com/attac-t/the-foundry/issues/156) proves it.

## What holds today

A delivery cannot silently claim it was checked against something it was not.

| Checkable with `git` and `cat` | How it fails loudly                  |
| ------------------------------ | ------------------------------------ |
| the bar was pinned at the base | a swapped pin contradicts the record |
| every clause was held          | an unheld clause is named as unheld  |
| the commit exists              | an absent commit is absent           |
| a swap was written down        | a made-up one has no record          |

**Every path to a lower bar runs through a visible, dated commit.** No path is silent.

*Silently* means the record does not fight itself and history does not show the act. It does not
mean it cannot be done.

## What does not hold yet

Each line is dated to the issue that would close it. None of them is claimed anywhere.

| Not true today                           | Owner                                                     |
| ---------------------------------------- | --------------------------------------------------------- |
| the suite that ran was the suite pinned  | [#341](https://github.com/attac-t/the-foundry/issues/341) |
| who said yes is more than the run's word | [#156](https://github.com/attac-t/the-foundry/issues/156) |
| a person can answer a judged clause      | [#343](https://github.com/attac-t/the-foundry/issues/343) |
| acceptance can be withheld               | [#359](https://github.com/attac-t/the-foundry/issues/359) |
| the record outlives the run directory    | [#337](https://github.com/attac-t/the-foundry/issues/337) |

**A hostile hand on the same shell defeats every wall here.** This catches accident, drift and the
easy path. It is not a security boundary. No sentence in this file may imply that it is.

## Strategy

**A bet, not a principle.** Every line here can be wrong, and each one says how we would find out.

| The bet                                                            | How it dies                                         |
| ------------------------------------------------------------------ | --------------------------------------------------- |
| framework authors first, because their bar is already written down | none of them writes a bar we can pin                |
| Claude Code is today's wrapper, not the product                    | a second harness costs more to add than it is worth |
| a repo far from here can run this                                  | the first foreign run needs a hand at every step    |
| the run record is worth keeping                                    | nobody reads one twice                              |

**Kill dates go on the issue, not here.** A bet with no way to lose is a belief.

## Vision

Not a promise. Dated to the five rows above.

> However fast change is produced, every delivery carries proof the owner keeps: this exact commit
> met a bar its producer could not lower.

Three of its words are false today: *proof*, *could not lower*, *the owner keeps*. It is kept whole
because it says where this is going. It is never quoted without these dates.

## For a repository Foundry is installed on

**That repository writes its own doctrine.** Its meaning comes from its humans, never from this file.

It cites this one by pin, never by paste. Where the two disagree about that repository, **its own
doctrine wins**, and it outranks everything Foundry ships there.
