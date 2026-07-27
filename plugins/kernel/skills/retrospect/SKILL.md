---
name: retrospect
description: Mine recent sessions for corrections that should have become memory. Stop re-teaching the same lesson.
---

# Skill: Retrospect

> "If you corrected me twice, that is my bug, not your job."

## Where This Runs

**In your project** — the repository you work in day to day, with the kernel
installed. Not in the plugin repo.

It reads that project's pull requests and your sessions, and writes to that
project's memory. Cross-project facts about how *you* work go to the user memory
directory; facts about this codebase go to branch memory.

## When

On a schedule — weekly. See [scheduling.md](scheduling.md).

Also after any session where you found yourself repeating an instruction.

## The Problem This Solves

Corrections arrive mid-task. You say *"no, we use Actions for that"*, Claude adapts,
the turn ends, and the lesson dies with the context window. Next week you type it
again.

Worse, a reviewer writes the same note on three different pull requests. That is a
convention nobody has written down, discovered three times at review cost.

Memory only captures what someone thought to record at the time. This reads what
actually happened.

## Not `consolidate-memory`

| Skill                 | Works on        | Asks                                  |
|-----------------------|-----------------|---------------------------------------|
| `consolidate-memory`  | Memory files    | Is what we wrote down still tidy and true? |
| `retrospect`          | Transcripts     | What did we never write down?         |

Run this first. It produces the entries the other one then tidies.

## The Sources

In priority order. Use what is available and say which were missing.

1. **Pull request reviews** — the strongest signal, because it is deliberate written
   feedback rather than a remark made mid-task. Requires `gh`.

   ```bash
   gh pr list --state all --limit 30 --json number,title,reviews
   ```

   Then, per PR that drew a review:

   ```bash
   gh api repos/{owner}/{repo}/pulls/{n}/comments --jq '.[] | {path, line, body}'
   ```

   Weight a `CHANGES_REQUESTED` review above a passing comment, and read the
   top-level discussion too (`issues/{n}/comments`) — the reasoning usually lives
   there rather than on the diff.

2. **Session transcripts** — `search_session_transcripts` for correction language:
   `actually`, `no,`, `don't`, `instead`, `I said`, `stop`, `that's wrong`,
   `we always`, `we never`, `remember`.
3. **Memory** — `MEMORY.md` and the memory directory, for what is already covered.
4. **Git history** — reverts, and commits that immediately amend a prior one.
   `git log --grep='^Revert' --oneline` is the cheap version.
5. **Blueprint failures** — the `Failures` section of `working.md` on recent branches.

> [!IMPORTANT]
> Availability differs by source. Transcript search is a desktop MCP tool, and `gh`
> needs a remote and an authenticated CLI. A headless or cloud run may have neither.
> Work from what is present and name what was missing — never report a clean
> retrospective off an empty search.

A review comment that was argued and then *rejected* is still worth reading. What the
maintainer refused tells you the boundary as clearly as what they asked for.

## The Bar

A correction becomes memory only when **every** answer is yes.

| Test           | Question                                                        |
|----------------|-----------------------------------------------------------------|
| **Repeated**   | Did it happen more than once, or would it obviously recur?       |
| **Durable**    | Is it still true next month?                                     |
| **Unrecorded** | Is it genuinely absent from memory and from `CLAUDE.md`?          |
| **Not derivable** | Would reading the repo *not* have told me?                     |
| **Actionable** | Does it change what I do, not just what I know?                   |

A one-off preference for one file is not memory. A correction you have issued three
times is overdue.

## The Protocol

1. **Gather** — search the sources above over the window since the last run.
2. **Cluster** — group corrections by theme. Frequency is the signal; a theme with
   three instances outranks a sharp one-off.
3. **Filter** — apply the bar. Most candidates die here.
4. **Write** — one file per fact, via `craft-observation` conventions:
   `feedback` for guidance, always with **Why** and **How to apply**. Route it:

   | The fact is about…                       | Goes to                    |
   |------------------------------------------|----------------------------|
   | How this codebase does things            | Project memory / `CLAUDE.md` |
   | How you prefer to work, anywhere         | User memory directory      |
   | A convention a reviewer keeps enforcing  | `CLAUDE.md` — it belongs in the repo |

   A convention three reviewers know and no file states belongs in `CLAUDE.md`, not
   in your private memory. Propose the edit; let the team own the rule.

5. **Prune** — delete memories now contradicted by how the project actually works.
   A wrong memory costs more than a missing one.
6. **Index** — one line per memory in `MEMORY.md`, and nothing else.

## The Output

```
Searched:  [N] PRs, [N] sessions, [window]   (unavailable: [list or "none"])
Clustered: [N] themes
Written:   [N] memories · Pruned: [N] · Rejected: [N]
Time returned: the [N] corrections you will not have to type again
```

`0 written` is a fine result. It means the last few weeks taught nothing durable.

## The Anti-Patterns

- **Recording the one-off.** One correction on one file is context, not a rule.
- **Losing the why.** "Use Actions" without the reason gets misapplied at the edges.
- **Duplicating the repo.** If `CLAUDE.md` says it, memory saying it again is noise.
- **Hoarding.** Never pruning turns memory into an archive nobody trusts.
- **Silent gaps.** If transcript search was unavailable, say so in the output.
