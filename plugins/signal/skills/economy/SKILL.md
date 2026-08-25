---
name: economy
description: Say more with less, do more with less — asked before writing, not as a polish pass. Use when producing any artefact: code, tests, prose, an issue, a PR, an RFC, a reply.
---

# Economy

> Agents write too much. They also build too much. Same reflex, same cure.

Polish removes words. It cannot remove the noun you invented, the fourth guard you bolted on, or the
abstraction you built for one caller — those are load-bearing by then. **The expensive waste is
decided before the first character is written.**

So ask first.

---

## The rule

> **What can be said in one word must not be said in two.**

## Where it sits

It is the fifth thing you do, never the first.

```
clear meaning → natural grammar → precise claim → useful structure → economy → the count
```

**Never reverse that.** A shorter sentence that a fluent speaker would not say is not shorter. It is
broken, and the count still passes.

## Cut the word, then read the sentence again

Swapping a word changes the grammar around it. Read the whole sentence out loud after every cut.

| Was | Cut to | What broke |
|---|---|---|
| *a bar its owner signed off on* | *a bar its owner signed off* | the preposition the verb needs |
| *the run it was graded against* | *the run it was graded* | same, and now it says nothing |

Both are shorter. Neither is English. This shipped in a doctrine and a reader stopped at it.

**If nobody would say it aloud, put the word back.**

---

## Before you write

| About to | Ask |
|---|---|
| add a noun — file, flag, table, stage, state | which failing case forces it? No case, no noun |
| write a second branch | that is a function you have not named. Name it; the `else` goes |
| add the Nth guard | why did N−1 not catch it? A pile of guards is one missing reader |
| write a paragraph | is it a table, a line of code, or nothing? |
| abstract | is there a second caller **today**? |
| explain the code | can the code say it instead? |
| state a guarantee | does the mechanism give it, or do you wish it did? |

Every answer of "none" or "no" removes work rather than tidying it.

---

## Two tests

**Said** — delete any sentence that would not change what the reader does. Then ask what the survivors
assume the reader already knows. That is usually another cut.

**Done** — could this outcome need fewer nouns, less state, or a smaller change? Ask it of the design,
not the diff.

---

## Tells

You have already failed when you write:

- a second paragraph balancing the first
- a comment narrating the line beneath it
- a function you scroll to read
- a fourth refusal in one function
- "may be affected", "consider whether", "in order to"
- a claim you cannot point at a mechanism for
- a rule stated unconditionally and applied selectively

---

## The boundary

**Not cryptic. Not fewer facts.** Precision is the point. A technical distinction lost to brevity is a
failure, not a saving — and cutting the qualifier that made a claim true is the worst outcome of all,
because it reads better and says something false.

Short and wrong is not economy.
