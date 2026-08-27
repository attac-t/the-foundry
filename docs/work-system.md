# The work system

One page. Where facts live, what the board shows, and what only you can do.

**The board:** https://github.com/users/attac-t/projects/1

---

## One owner for each fact

The board shows work. It makes none of it true.

| Fact | Lives in | Written by |
|---|---|---|
| what we are trying to achieve | `.foundry/goals.md` | a named person, deliberately |
| what a change must become true | the issue, and its `## Done when` list | whoever files it |
| how the work was done, and the proof | the run record | the run |
| what is proposed, and whether to take it | the pull request | the producer, then a reviewer |
| what is now true | merged history | the merge |

**The board mints nothing.** Not a goal, not evidence, not authority, not completion. Move a card
and the work does not change. It is a saved question, not a state.

---

## The five views

Names and filters a host may rename, hide or replace. They are queries, never phases.

| View | Asks |
|---|---|
| Now | what needs eyes — anything whose Attention is not `none` |
| Next | open issues nothing is waiting on |
| Review | open pull requests |
| Decide | only what a person must answer |
| Done | closed work, with rejected and superseded still tellable apart |

---

## Four fields, and only four

Everything else is GitHub's own — Status, Assignees, Labels, Linked pull requests, Updated.

| Field | Says | Changed by |
|---|---|---|
| Attention | `none`, `a person decides`, `blocked` | a run, or you |
| Next action | the one move that advances it | a run, or you |
| Evidence | where the proof is, as a link a reader can open | a run |
| Observed | when these facts were last looked at | a run |

**Attention is not Status.** Work can be in review and need nobody. It can be blocked with nothing
for you to decide. One field cannot say both, so there are two.

---

## What stale means

`Observed` is when a run last looked. It is not live.

A missing record, a failed read or an old stamp all mean **unknown**. None of them means idle, clean,
ready or done. If `Observed` is old, the row is a memory, not a fact.

---

## What only you can do

- accept a goal, which makes it current
- answer anything in `Decide`
- tick a `## Done when` box, which is what lets an issue close

**A merge is not acceptance.** It lands a change. Whether the outcome was wanted is a separate act,
recorded separately, with your name on it.

---

## Adding to it

Adding a column is presentation:

```
gh project field-create 1 --owner attac-t --name "Security" --data-type SINGLE_SELECT --single-select-options "not started,passed"
```

Adding a real requirement is not. A gate is declared where the bar lives, and it blocks:

```
printf 'security  make security-scan\n' >> .foundry/gates
```

**The first changes what you see. The second changes what may happen.** A status called `Approved`
waives nothing.

---

## Its limits, plainly

- A cloud wake fires hourly at most, and cannot grade Floor. It reports; it does not work.
- Hosted checks are unpaid. A red check on a pull request means nothing.
- The board is a view. Losing it costs visibility, never execution or authority.
