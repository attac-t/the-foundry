# Running

A run holds the work. Take one before you touch anything.

---

## The rule

**Before you act on a work item, open a run for it.** One run, one attempt, one item.

```sh
sh plugins/floor/bin/run.sh new "<the item, in your own words>"
```

That is the whole instruction. Everything below says why it is a rule and not a habit.

## Why it is a rule

**Nothing asked for a run, so nobody opened one.** 148 runs sit on the machine that built this and
every one is from August. Eight days of merges, issues and charters followed, and the run home
recorded none of them.

The mechanism was written down and the process that governs the work never reached it. **This line
is that missing step.**

## What it buys

| | |
|---|---|
| a restart finds the work | the checkout points at its run in `.git/foundry-run`, so a fresh shell picks it up |
| two workers cannot own one item | a claim is a directory, and the second `mkdir` fails |
| the record outlives the session | a run is not in the chat and not in the tree |

**A sentence saying you started is not a start.** The run is.

## Where it sits

Take the item, open the run, then do the work. Not after the first commit, and not at the pull
request — by then the thing a crash would lose has already happened.

Filing an issue is not acting on it. **Working on one is.**

## What it does not do

**Nothing enforces this.** A run lives outside the tree, so no exit code can see one. A worker that
skips the line leaves no trace until somebody asks.

That is the open half, and [#546](https://github.com/attac-t/the-foundry/issues/546) owns it.

A run grants nothing. It records that work began, and [`identity`](identity.md) still decides who
began it.
