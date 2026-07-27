# Scheduling Retrospect

Schedule this **in your project**, not in the plugin repo. It mines your pull
requests and your sessions, and writes your memory.

Weekly. Frequent enough that a theme is still recognisable, rare enough that a
single correction has had time to repeat and prove itself.

---

## Prefer a Local Schedule

Unlike [`evolve`](../evolve/scheduling.md), this skill's richest source is your own
session transcripts, and those live on your machine.

| Mechanism                  | Transcripts | PR reviews | Use for `retrospect` |
|----------------------------|-------------|------------|----------------------|
| **Desktop scheduled task** | Yes         | Yes        | ✅ Best              |
| **`/loop`**                | Yes         | Yes        | ⚠️ Ad hoc only — 7-day expiry |
| **Routines** (cloud)       | No          | Yes        | ⚠️ Partial           |
| **GitHub Actions**         | No          | Yes        | ⚠️ PR reviews only   |

A run without transcripts still works — PR reviews, memory, git history, and
blueprint failures all survive a fresh clone, and PR reviews are the strongest source
anyway. It just cannot read what you said in chat, and it says so rather than
implying a clean week.

A CI-scheduled run is therefore worth having even on top of a local one: it sees every
review comment on the repository, including reviews left by people who are not you.
On a team, that is the version that finds the conventions nobody documented — and its
output usually belongs in `CLAUDE.md` rather than in one person's memory.

---

## Local (Desktop scheduled task)

Configure a weekly task in the desktop app with the prompt:

> Invoke the `kernel:retrospect` skill.

Pick a time you are not working — the scheduler fires between turns, and a
retrospective mid-task is a distraction.

---

## Ad Hoc

After a session that felt repetitive:

```
/retrospect
```

This is often the highest-yield moment. The irritation of repeating yourself is the
signal, and it is freshest right then.

---

## A Note on Cadence

Do not run this daily. The bar requires a correction to have **repeated**, and a
daily run sees each one exactly once, so it either records noise or records nothing.

Weekly gives a theme room to appear twice.
