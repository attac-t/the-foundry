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

**A mechanism nobody is told to use is a mechanism nobody uses.** The run has shipped for a while.
The process that governs the work never named it, so the work went on beside it.

**A rule is where that step belongs.** The moment it applies is the moment before anyone
thinks to look one up.

## What it buys

| | |
|---|---|
| a restart finds the work | the checkout points at its run in `.git/foundry-run`, so a fresh shell picks it up |
| the record outlives the session | a run is not in the chat and not in the tree |

**Exclusivity is not on that list, and it used to be.** `run.sh claim <item>` refuses a second
holder, proved at 1,000 rounds and 1,000 single winners. **`new` never calls it.** So opening a run
buys none of that.

**A sentence saying you started is not a start.** The run is.

## Where it sits

Take the item, open the run, then do the work. Not after the first commit. Not at the pull request.
By then a crash loses the thing you meant to record.

Filing an issue is not acting on it. **Working on one is.**

## What a run needs after `new`

**A bare run is enough, and it is enough for two things.** It survives a restart, and it records
that work began. That is the whole of what `new` does.

**It does not claim anything, and this page said for six days that it did.** `new` writes the title
and emits `run.began`. Nothing else.

A claim is renewed through the item a run holds. An item is bound by `run.sh source read <item>`,
and **6 of 222 runs here hold one**, measured 20 September.

**So the documented path buys no exclusivity.** Two workers can open a run for the same work and
neither is refused. [#925](https://github.com/attac-t/the-foundry/issues/925) owns whether that
changes or whether the page simply stops promising it.

**It cannot say what the work proved.** Nothing reads a workspace and works that out.

```sh
sh plugins/floor/bin/run.sh observe <event> key=value ...
```

**Nothing calls that for you.** 14 of 119 on 14 September 2026; **112 of 222 on the 20th**.

**The share is rising and every line was typed.** Two runs carry `session.ended`, written by floor's own hook, and that is the whole of what survives a worker who forgets.

So the rule is two lines, not one. **Open a run before you act. Record what it proved before you
stop.** The second is the half that is missing, and
[#595](https://github.com/attac-t/the-foundry/issues/595) owns closing it.

## What it does not do

**Nothing enforces this.** A run lives outside the tree, so no exit code can see one. A worker that
skips the line leaves no trace until somebody asks.

That is the open half, and [#546](https://github.com/attac-t/the-foundry/issues/546) owns it.

A run grants nothing. It records that work began, and [`identity`](identity.md) still decides who
began it.
