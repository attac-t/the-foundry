---
name: craft-swimlane
trigger: swimlane, handoff, touchpoint, who does what, responsibility boundary
description: Draw who or what acts at each step, and what crosses between them. Use when a hand-off, an approval, a human touchpoint or an adapter seam is the point. Not for static structure (craft-map), ownerless process (craft-flow), or a call and return trace.
---

# Craft Swimlane

> "A flow shows what happens. A swimlane shows who it happens to, and what crosses."

## Which of the three

| `craft-map` | what exists, where it lives, what each part is for |
| `craft-flow` | what happens next, in what stages, where it branches |
| **`craft-swimlane`** | **who acts, who decides, and what crosses between them** |

**Reach for this when sequence alone hides the answer.** If the important fact is who owns a step, or
what passes a boundary, a flow will not show it.

## One scenario

Name the question, the start and the end. **Never the whole product.**

*How does a request become a merged change?* is a scenario. *The system* is not.

## A lane is a responsibility

Every lane answers the same question: **who or what is accountable here?**

A person, a role, a system, a plugin, an adapter. Never a file, a folder or a step.

Four to six lanes. More than that, and you are drawing two scenarios.

## Time runs down

Lanes sit left to right. Actions descend. Same house style as `craft-flow`.

## Every action has one home

Put each action in exactly one lane. Start its label with a verb.

**A decision lives where it is made**, never where its result is used.

## Every crossing says what it carries

**No bare arrow.** Label what passes.

```
──▶   a request, a work item, a decision, a delivery, responsibility
╌╌▶   information, an observation, evidence. Authority does not
```

Two arrows and nothing more. **The label carries the meaning.** An arrow never grants authority by
being drawn.

## A human touchpoint is a decision

Where a person is involved, show four things:

| what reaches them |
| the one decision they own |
| what comes back |
| what carries on without them |

**Never a box saying "approval".** Name the trade-off they own. And never add a person where no
meaning, consequence or authority is at stake.

## Adapters live at the edge

Use the names the model uses: work source, execution, judgement, delivery, outcome.

GitHub, a directory, Jira — an annotation at the edge, or a lane of its own only when the adapter
itself is the scenario.

**The same drawing should survive a different work source.** If it does not, you drew the provider,
not the system.

## What is missing is part of the picture

**Do not draw an arrow because two things are installed.** Draw it because one calls the other.

Where two parts meet only through direction, work, evidence and outcome, the gap between their lanes
is the finding. A swimlane that hides it is worse than none.

## Before you publish it

Ask a reader who was not there:

1. Who acts at each step?
2. Who decides?
3. What crosses each boundary?
4. Where does a person get stuck?

**If they cannot say, the drawing failed.** Adding boxes will not fix it.
