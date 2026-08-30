# Goals

The index. One record per goal, in priority order.

**A run may draft a goal. Only a named person accepts one.** An acceptance is written down and
dated, and says who. A merge never accepts a goal. It lands a file.

| Goal | State | Accepted |
|---|---|---|
| [Foundry runs itself](goals/foundry-runs-itself.md) | partly | 27 August 2026, [recorded](decisions/foundry-runs-itself-is-critical.md) |
| [A person can run it without being told how](goals/a-person-can-run-it.md) | proposed | Not yet |
| [A repository states its bar](goals/a-repository-states-its-bar.md) | partly | Not yet |
| [What is believed stays in touch with what is true](goals/beliefs-meet-reality.md) | proposed | Not yet |

**One is accepted, and three are not.** A run may work on the first. On the others it should say
they are unaccepted rather than pick one. That is the honest answer, not a gap to fill.

## Outcomes with no record yet

[Doctrine](doctrine.md)'s strategy implies five more outcomes. **None is a goal**, because none has a
record and none has been accepted. They are kept here so the wording is not lost while a person
decides whether any of them is one.

| Outcome | Nearest record |
|---|---|
| a fresh session states the direction from the accepted base, and says which goal its work advances | none |
| the daily loop makes a readable proposal, or one honest reason nothing useful could proceed | none |
| the same core path works through a second harness, and each capability stays useful alone | none |
| a cold reader can name the intent, the change, the evidence, the doubt and the next decision | none |
| a founder, designer or domain expert states one scoped outcome and reads the result, in their own words | none |

Two more sit in the table above already: an honest first path is
[a person can run it](goals/a-person-can-run-it.md), and closing the learning loop is
[beliefs meet reality](goals/beliefs-meet-reality.md).

**Writing a record does not accept a goal.** It moves the wording out of a proposal and into a place
a person can say yes or no to.

## Where an acceptance is written

In [`decisions/`](decisions/), one record per decision, quoting the words the person used.

**A run writes that record.** Taking down what somebody decided is secretarial work, not authority.
The record informs and never grants. What a run may never do is decide, or write an acceptance
nobody gave.

**The quote is exact and is never edited**, whatever a word counter says about it. Trimming
somebody's decision to score better would falsify the one thing the record exists to hold.

---

## What lives here, and what does not

This file is an index. A goal's own record holds its outcome, its `Done when` list, its state, its
acceptance and its evidence.

Tasks, plans, work logs and lessons live where the work does. An issue, a pull request, a run
record. A goal links to them and never absorbs them.

**Doctrine holds what does not change.** Identity, mission, principles. It links here and copies
nothing.

## Adding one

Write a record under `goals/`, named for the goal, and add a row above. Leave `Accepted: Not yet`.

**The file name is the id.** A counter collides. Two branches both take the next number, the files
land side by side under different names, and nothing conflicts. A silent duplicate id is worse than
a merge conflict.

Two branches adding the same goal collide on the file, which is right. Two branches adding different
goals never do.

**Never rewrite a past condition so a result passes.** Git records the edit; the goal says why the
direction changed. A goal that is finished, withdrawn or replaced keeps its record and says which.
