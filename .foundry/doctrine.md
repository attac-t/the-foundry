# Doctrine

Why Foundry exists, who may say what good means here, and what is not true yet.

**A run reads this and never writes it.** Every line was ratified by a human, at a commit, on an
issue anyone can open. A change here binds nothing until a human commits it and a later run reads it.

---

## Mission

> **Keep every change answerable to the humans who ratified the bar it must meet.**

The short form:

> **Every change answers to a bar its producer did not ratify.**

**Did not, never could not.** *Could not* is a guarantee this does not give. A producer on the same
shell can edit any file here, and v1 does not close that. What holds is narrower, and it is written
down below.

## Principles

| | |
|---|---|
| the producer never owns the bar | it may propose one. It is never the hand whose commit makes one bind |
| a record informs, never grants | who may say yes is read from history, never written by the run that needs it |
| only a human decides meaning | a machine may grade, draft, ask and refuse. It may not say what good is |
| every part ships alone | a plugin that needs another to be useful is one plugin wearing two names |
| say what is not true | an unverified claim, a residual risk and a known gap each get a sentence, and the sentence says which it is |

## Authority

**The boundary is the claim, not the file.** A repository has as many authorities as kinds of claim.
One person may hold every one. That is a small map, not a different model.

| Term | Means |
|---|---|
| producer | proposes or performs the change. A role per change, never a kind of person |
| authority | who may ratify a claim. Named by the map, for the claim's pinned source |
| decision-maker | the named authority for one trade-off, recorded inside that decision |
| acceptor | who accepts a delivery. Today it cannot be withheld, and it is self-reported |
| accountability | who answers for a result. Traced, never granted, and never authority |
| ownership | never used bare. Repository, product and IP are three facts, not one |

### The map

One map per governed repository. It says which claims answer to which humans.

> **A map states how it changes, or it is not a map.**

Ratified on [#128](https://github.com/attac-t/the-foundry/issues/128), 25 August 2026. Without that
rule the installer quietly becomes the owner of everything. That is the model rejected here.

| Repository | Its map |
|---|---|
| one person | one generated line. Convention first, so nothing is written by hand |
| a team | claim authorities and conflict rules, written out |

**A map change is ratified under the rule already in force, and binds later runs only.** A map that
changed under its own new rule could rewrite its own authority in a single commit.

### Six rules

1. The pinned source picks the row. The map names the human.
2. A change answers only to ratifications at or before its base. Its own writes bind nothing for it.
3. Assent is a dated, attributable record. Silence and merge are never assent.
4. A true conflict goes to written precedence. Absent that, the trade blocks until the conflicting
   authorities jointly ratify. The block scopes to the trade, and other work carries on.
5. Anyone proposes a map change. Only the change row ratifies it.
6. Cite, never create. Nothing a producer writes may create authority, assent or a verdict.

**A named human in a map is a record, not a control.** Foundry does not claim to know who wrote a
line. It will not claim that until [#156](https://github.com/attac-t/the-foundry/issues/156) proves it.

## What holds today

A delivery cannot silently claim it was checked against something it was not.

| Checkable with `git` and `cat` | How it fails loudly |
|---|---|
| the bar was pinned at the base | a swapped pin contradicts the record |
| every clause was held | an unheld clause is named as unheld |
| the commit exists | an absent commit is absent |
| a substitution was recorded | an invented one has no record |

**Every path to a lower bar runs through a visible, dated commit.** No path is silent.

*Silently* means without the record contradicting itself or history showing the act. It does not mean
impossible.

## What does not hold yet

Each line is dated to the issue that would close it. None of them is claimed anywhere.

| Not true today | Owner |
|---|---|
| the suite that ran was the suite pinned | [#341](https://github.com/attac-t/the-foundry/issues/341) |
| who ratified is more than the run's word | [#156](https://github.com/attac-t/the-foundry/issues/156) |
| a person can answer a judged clause | [#343](https://github.com/attac-t/the-foundry/issues/343) |
| acceptance can be withheld | [#359](https://github.com/attac-t/the-foundry/issues/359) |
| the record outlives the run directory | [#337](https://github.com/attac-t/the-foundry/issues/337) |

**A hostile hand on the same shell defeats every wall here.** This catches accident, drift and the
easy path. It is not a security boundary. No sentence in this file may imply that it is.

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
