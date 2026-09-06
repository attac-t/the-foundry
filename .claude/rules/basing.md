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

## Why a rule and not a gate

Every gate here reads the tree. **This fault is only visible in a diff**, between two trees that are
each fine on their own. No exit code can hold it.

The same reason `closing.md` is a rule: the check happens before the work is judged, so nothing
downstream can catch it.

## An agent needs telling twice

Say it in the brief at the start, and say it again as the last step.

**Half an hour is enough for the base to move here.** An agent that read the instruction on
minute one has spent its context by the time the instruction matters.
