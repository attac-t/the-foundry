# Closing

An issue closes when its own list says it may.

---

## Every box, ticked

**Read the whole `## Done when` list before closing anything.** Tick what holds, against the check
that proves it. What does not hold keeps the issue open, or moves to an issue that owns it.

Closed with an unticked box is a lie the tree tells the next reader. It is worse than an open issue,
because nobody looks again.

#163 closed with two of five unmet. The list was read down to the third line and the rest were never
seen.

**And say so when the last box is ticked.** Five items here had every box ticked and no word that
they were done, one of them saying DONE in its prose while its list stayed silent. A reader scans
boxes, not paragraphs, and an unannounced finish reads as work still open.

## Tick before you merge, not after

**`Closes #N` shuts the issue whether or not its boxes hold.** It reads nothing. The merge lands,
the issue closes, and the list is exactly as unticked as it was.

A hook here does notice, and it says so — *closed by this merge with N open.* **It fires after the
merge**, which is after the lie is already on the page.

It happened on 14 September. Four of five boxes held, one was genuinely unbuilt, and the request
carried `Closes`. The issue closed, the hook spoke, and the only repair was to reopen it.

**So tick the list on the issue before the request merges.** A box that will not tick is a box that
keeps the issue open, and then the request says `Refs` rather than `Closes`.

**`.claude/hooks/closes.sh` now refuses that merge.** It reads the request body before `gh pr merge`
runs, counts the open boxes on every issue the body would close, and denies while any stands. It
names the issue, the count, and the line it matched.

**The keyword is nine words, in any case, anywhere in the body.** `close`, `closes`, `closed`,
`fix`, `fixes`, `fixed`, `resolve`, `resolves`, `resolved`.

On 15 September a body ending `Refs #711, #738` closed #711 with one box open. **What fired was
prose** — *this closes #711's last box and nothing else* — and the close event carries no commit, so
afterwards it does not even read as a keyword close.

**Some boxes can only be true after the merge.** #711's last one was *`.foundry/status.md` names
#738*, a claim about `main`. **That box can never tick first.** So the request says `Refs`, it
merges, and a person closes the issue by hand against the merge tree.

**Compare trees, never commits.** A merge commit has a new hash and the same tree, and the tree is
what a gate read.

**The hook is lint.** The worker holds the same account and can edit it, so it closes the easy path
and nothing more. `ticks.sh` still reports after the merge, and that remains the audit.

## A box that cannot be met yet

Say so on the issue, and say which of four things it is:

| | |
|---|---|
| unmeetable here | it wants something this stage does not have — move it to the issue that will |
| wrong when written | the requirement itself was mistaken — strike it, and say why |
| ungateable | the outcome is reachable and no check can hold it — say which half is which |
| **unreached** | the check is right and nothing has happened for it to read — **leave it open** |

None of the four is a tick. A box removed silently and a box ticked wrongly read the same six months later.

**Write the state as the first bold word in the box**, so a check can read it:

```
- [ ] the check is right and nothing has happened for it to read — **unreached.** Four goals, none finished
```

**`bin/unticked.sh` reads that word.** A box naming one of the four is answered and is not counted as debt. A box saying nothing is, and the exit code follows only those. Measured 19 September: thirty-four open boxes across thirteen closed issues, seventeen naming a state and eight saying nothing.

**A bold word that is none of the four is reported, not counted either way.** Three boxes read `**unverifiable**` — the check ran and what it read cannot be confirmed afterwards, which is not *ungateable*, where no check can exist. **Whether that is a fifth state is a person's call**, and the report exists so nobody has to notice it by hand.

**A moved box is the one that rots.** The other three end. This one waits on an issue somebody else
will close, and nothing walks back when they do.

#625 moved a box to #630 and said so. **#630 closed six of six on 9 September**, and its first box
is that box in its own words. The source read as open work for five days. A sweep of twenty-five closed
issues found it, and it was the only one carrying an unticked box.

So: **when you close an issue, tick every box that moved to it.** The move names the destination;
only the destination knows the day.

**Unreached is the one that looks like the others and behaves opposite.** The first three end a box.
This one keeps it, because the day the condition arrives the check costs nothing.

*Completed and superseded goals stay discoverable* cannot be checked while no goal has completed.
**Four goals: two partly, two proposed.** Nothing finished, nothing replaced, so a working mechanism
and an absent one read alike. **Ticking it would claim a check nobody ran. Moving it would give away
a box that is simply early.**

**Ungateable is the one that gets miscalled.** #305 wants a markdown table readable as raw text.
Pad the columns and it is. **No gate can prove it** — `length` counts bytes in one locale and
characters in another, so a table one `awk` calls aligned is ragged to the next.

I nearly filed that as unmeetable, from the rule rather than the issue. **A discipline nobody can
check is still a discipline**, and writing it off closes an issue that was never blocked.

## A list that was never a list

**Ninety issues are closed here. Two hundred and nineteen of their claims are plain bullets**, spread
across forty-seven of them — written before `- [ ]` was required, so nothing could be ticked and
closure recorded nothing about any of them.

They are not silently unmet. **They are unrecordable**, which is a worse thing to find and a cheaper
thing to answer: an unrecordable claim is unverified, and it becomes work the day something
contradicts it. Reopening forty-seven issues to tick boxes nobody can check is a different waste.

Converting a closed issue's list is worth it only when someone is about to rely on it.

## A closed issue is not an owner

**Twelve closed issues here are still pointed at by an open one.** A reader follows the link, finds
a closed page, and reads the gap as handled.

`.foundry/status.md` already says this of merged work. It holds for a closed issue for the same
reason: **closing records that a list was answered, never that somebody is still watching.**

So say which of two things a pointer means. *This was settled there* is a fact and needs nothing.
*That owns the rest of it* is a claim about the future. **A closed issue cannot carry one.** Move
the remainder to an open issue, or write the answer where the pointer is.

**The twelve were read back on 20 September**, each against the tree, and none was reopened. Six
hold in full, three in part, one is plainly unfinished, and two landed a shape without the answer.
Reading was the whole of the repair.

## Look for the work before you start it

**Three charters were written on 1 September, and nobody opened one for two days.** 190 KB on
disk, while the standing list called all three *not started*.

Their boxes were not failing. **They were unread** — which looks identical from outside the file
and is the opposite finding. A failing box is work to do. An unread one is work to record.

Reading a 160 KB charter against its brief took one pass and closed eight boxes of nine. The list
had shown none.

**So look before you start.** A brief says where its output goes. Nothing tells you it arrived.

**And the fault is in a summary, never in a list.** A box names the thing to check, so checking is
cheap and someone does it. A summary restates, and a restatement has nothing to check against.

Eleven wrong summaries turned up in one day. Ten said less than was true, and one said more.
**Nothing pulls a summary back either way.** A sample of eight boxes, the same day, was right eight
times. So write the check, never the verdict.

## A box the change makes true is not a box a test holds

**Ask of every tick: what would go red if this stopped being true?** If the answer is nothing, the
box was closed on reasoning.

Three went that way in one day. Each was true. The logic was sound and the code was right, and no
check would have noticed the day either stopped.

The tell is the shape of the claim. *A path from another machine is not this repository* is a fact
about a comparison, and a comparison can be driven in one line. **It closed on the argument
instead**, and the fixture came afterwards, as its own change.

**Driving it costs a line and buys the box.** Reasoning costs nothing and buys a sentence somebody
will believe six months from now.

**And a fixture is not enough on its own.** Break the thing it guards and watch the check go red. A
case that passes against broken code was never holding the box — `bin/breaks.sh` exists for that at
the gate level, and a `## Done when` list deserves the same.

## Nothing checks this

The gates are offline and an issue lives on a service. **This is a rule because no exit code can
hold it**, which is the whole reason it has to be read before the work starts rather than after.
