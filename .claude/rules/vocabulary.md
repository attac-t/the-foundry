# Vocabulary

The words a capability is known by. Its verb, its nouns, and the sentence that explains it.

All three are chosen before it is built. **A name picked afterwards is a name fitted to the code**,
and the reader was never in the room.

---

## Why this is a rule

Doctrine's strategy table already names the failure. *Make the ordinary path the product* — **dies
if a first useful proposal means learning internal verbs or wiring plugins by hand.**

**Nothing asks.** Measured 9 September 2026:

| Who | Asks | Misses |
|---|---|---|
| `panel:craft-charter` | what must become true, how we would know, what is out of scope | **never what it will be called** |
| `kernel:ground-naming` | `CreateOrder`, `isValid`, no type suffixes | code identifiers, not a capability's public verb |
| `panel:newcomer` | reads cold, reports confusion | **after it is built.** Reactive by design, and it says so |
| `panel:adversary` | judges the work against the charter | after, and only what the charter asked for |

So the one question that decides whether a stranger can use the thing is asked by nobody, and
asked last.

## Four questions

Ask them at the charter, in the same breath as *what must become true*.

**What verb does this answer to?** One word.

Two words means one of two things. Either it is two capabilities, or the first word is a category.
A category belongs in the name of the thing that holds it.

**Write the sentence a stranger reads.** One line, in the imperative, naming what they get. If it
needs a second sentence to stop being ambiguous, the verb is wrong.

**What would they guess it was called?** If your answer and their guess differ, theirs wins.

You knew how it was built and they did not. That is the whole test.

**What nouns does it add, and which failing case forces each?** None is the usual answer, and the
usual answer is right.

A noun fails the opposite way to a verb. **A wrong verb is unguessable. A wrong noun is guessable
and means something else already.** Two names for one idea read as two ideas, and the reader spends
the rest of the page looking for the difference.

`worker`, `agent`, `executor`, `runner`, `operator`, `harness` — six words, and a repository that
ships all six has taught nobody anything. **One idea, one name.** `kernel:craft-sh` says the same
of a variable, and it holds harder in public.

## The test that settles it

**Write the documentation line before the code.** Not the whole page. The one line in the table of
capabilities.

If that line reads as obvious, the verb holds.

A clause explaining the mechanism means the verb describes how it works, not what it does.

`run`, `claim`, `deliver`, `join` pass. A verb naming its own machinery does not.

## What this is not

**Not a ban on internal names.** A function inside a file answers to whoever reads that file.

This governs what a person outside reaches for. A command, a skill, a hook point, a verb in a
contract.

**Not a gate.** No exit code can judge whether a word is obvious. `writing.md` says why that kind
of measure is untestable.

A newcomer read is the nearest thing, and it comes too late to be this.

**Not a plugin dependency.** The rule names skills where they help.

It states the constraint whether or not any of them is installed. None of them needs another to be
useful.
