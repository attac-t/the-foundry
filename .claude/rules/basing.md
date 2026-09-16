# Basing

A branch cut before a merge quietly undoes it.

---

## The shape

Branch from `main`. Work for half an hour. Something else merges while you work.

Your branch never held that file, so git has no reason to complain. **The merge is clean and the
diff deletes a shipped file.** A conflict announces itself. This does not.

It happened twice on 6 September. One branch would have removed a gate that landed an hour earlier —
154 lines, and every check on it.

## What to do

**Merge `origin/main` into the branch before you open the request, then read the stat line.**

```sh
git merge --no-edit origin/main
git diff --stat main HEAD
```

**A deletion on a file your change never names is the tell.** Nothing else says it.

**Resolve the conflict first, or the stat lies.** While a merge is unresolved, `HEAD` is still your
old commit, so the diff reports every merge your branch predates as a deletion.

On 14 September that read as **99 deletions across five files** — all of them work that had landed
hours earlier. Resolved and committed, the same command said two files and nothing deleted.

**A stat taken mid-conflict is noise, and it wears the tell's clothes.**

## Inside a run, this rule can make the work ungradeable

**A run's base is pinned, and its charter hangs off that commit.** Merging `origin/main` into a run's
workspace brings whatever main changed — and when main changed a file the charter pins as a gate,
floor refuses to grade at all:

```
floor: grading with the base's own gates: bin/host.sh bin/taper.sh
floor: each was graded as the base wrote it, so a gate reading one saw neither tree whole
floor: a change to the bar itself is landed by a person — no run can prove it
```

Exit 14, and nothing graded. **That is invariant 1 working**, not a fault.

**So the rule above is for a branch.** A branch has no pinned base and no charter. A run has both.

**The reconcile belongs at the merge, not before the grade.** A run proves its work against the bar
it was chartered on. What main did since is settled when the work lands, by a person, the
way any other conflict is.

**A judge will read the staleness as a defect, and it is not wrong to.** One did here, on
13 September: seventeen commits ahead, six behind, and the same runner changed on both sides. The
answer is this section, not a merge the run cannot then grade.

## A check holds half of it now

`sh bin/basing.sh [<target>]` names every file that loses lines and this branch never touched. It
refuses with exit 1 and prints the merge to run.

**It refuses to answer mid-conflict**, exit 3, because `HEAD` is the old commit while a merge is
open and the diff would then name every merge the branch predates.

**Two trees, never `...`.** Three dots compares against the merge base, where a file the target
added after the cut is simply absent — so the deletion never appears. That was written and driven,
and the fixture caught it.

## Why it is not a gate

Every gate here reads one tree. **This fault lives between two**, so no gate can hold it — and a
check can, because `git diff` takes two refs.

`bin/basing.sh audit` is gated. The check itself belongs where a request is opened.

**It reaches git and nothing else.** Three calls — `rev-parse`, `diff`, `merge` — and no forge. The
fault is git's: a clean merge that removes shipped work, on any host of any remote. **The forge is
one adapter**, and the doctrine says so.

The same reason `closing.md` is a rule: the check happens before the work is judged, so nothing
downstream can catch it.

## An agent needs telling twice

Say it in the brief at the start, and say it again as the last step.

**Half an hour is enough for the base to move here.** An agent that read the instruction on
minute one has spent its context by the time the instruction matters.
