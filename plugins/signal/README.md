# signal

> Plain English harness. How to speak.

Agents write too much. This cuts it by ten, and holds the cut with a gate.

---

## Why a hook and not a style

An output style asks. A hook refuses.

We tried the style first. It drifts: the voice holds for three replies, then the old habits come
back. Nothing measures whether it worked, so nothing stops it slipping.

A `Stop` hook gets the agent's finished reply and can hand it back. That is the whole idea.

---

## How it works

Every time the agent stops talking, the hook scores the reply and picks one of three answers.

| Answer | What happens | Cost |
|---|---|---|
| pass | Nothing. You never see the hook | none |
| warn | You get the numbers. The agent does not | none |
| block | The agent gets the numbers and says it again | one turn |

The agent gets one block per turn, not a fight. If the rewrite is still over, it ships — and you get
a note saying so. Nothing goes wrong quietly.

Knowing whose block it was needs more than the flag Claude Code provides. `stop_hook_active` says
*some* stop hook is why the turn is still going, not which one. Any other plugin can hook `Stop` and
block for its own reasons. So the flag alone made signal stand down on replies it had never scored.

So when we block, we write the prompt id to a **marker**. That is a small file in your temp
directory, one per session. We stand down only for the prompt it names. `SessionEnd` deletes it.

---

## The numbers

Three counts. No word list.

| What we count | Pass | Warn | Block |
|---|---|---|---|
| Long words | up to 10% | over 10%, up to 15% | over 15% |
| Longest sentence | up to 20 words | 21 to 30 | over 30 |
| Words in all | up to 120 | 121 to 250 | over 250 |

Each band ends where the next begins. Exactly 10% passes.

**Beats** are syllables. `use` is one beat, `useful` two, `utilise` three. We count vowel groups, so
it is an estimate, not a dictionary.

**Long words** means three beats or more. The share covers prose *and* table cells. Names and paths
leave both sides of the fraction, so a wall of product names cannot water it down.

**Words in all** is a different set on purpose: prose only, table cells excluded, names included. A
table is easy to skim, so it should not spend the budget. A hard word is hard wherever it sits.

---

## Why long words and not a reading score

Reading scores lean on words per sentence. Break each clause onto its own line and the score falls,
while the words stay just as hard. We measured that on real files here:

| File | Reading score | Long words |
|---|---|---|
| A page written to be plain | 0.6 | 1.8% |
| A skill doc from this repo | 6.0 | 12.5% |
| A voice guide from this repo | 7.4 | 23.2% |

A grade-6 bar waves the middle one through. Long words put it at seven times the first. So we gate
on long words. The scorer still reports a `grade` field for anyone running it by hand. The hook
never reads it, and it gates nothing.

---

## Word choice is judged, not listed

We shipped a list of 209 banned words first. It was the wrong shape.

Hard words are an open set. They never stop arriving. Any list of them samples something endless,
and is stale the day it ships. A list also invites false alarms: `issue` looks bannable until
someone writes "GitHub issue".

So the counts measure shape, and a standard handles word choice.
[`signal:plain-english`](skills/plain-english/SKILL.md) names
[ASD-STE100](https://www.asd-ste100.org/) and [ISO 24495-1](https://www.iso.org/standard/78907.html),
shows a dozen examples, and carries the three-step test to run on each word. The skill owns that
test; this page does not repeat it.

Terms of art survive the test on purpose. `worktree` and `idempotent` stay, because being vague
costs more than being long.

The counts turn out to do most of the work anyway. `utilise` is three beats, `facilitate` four,
`additionally` five, so the long-word share already catches them.

**What we gave up, exactly.** Short unusual words now pass the counts. *"We shall hence deem it
thus, whilst the crux is moot"* scores 0% long words. Only the test catches that, and the test is a
judgment, not a gate. We think that trade is right. A gate that fires on `issue` gets switched off,
and then nothing is enforced at all.

---

## Install

Needs: Claude Code CLI, `bash`, `awk`. No Python. No Node. No `jq`.

```
/plugin install signal@the-foundry
```

It starts working on the next reply. There is no style to switch on, so whatever output style you
already use keeps working beside it.

---

## Tune it

The hook reads six environment variables.

| Variable | Ships as |
|---|---|
| `SIGNAL_LONG_WARN` | 10 |
| `SIGNAL_LONG_BLOCK` | 15 |
| `SIGNAL_SENT_WARN` | 20 |
| `SIGNAL_SENT_BLOCK` | 30 |
| `SIGNAL_WORDS_WARN` | 120 |
| `SIGNAL_WORDS_BLOCK` | 250 |

**For one project**, put them in that project's `.claude/settings.json`:

```json
{
  "env": {
    "SIGNAL_LONG_WARN": "5",
    "SIGNAL_WORDS_WARN": "80"
  }
}
```

**For every project**, use `~/.claude/settings.json` instead. **For one session**, export them in
the shell before you start Claude Code.

The suite tests the shell route directly. The `settings.json` route relies on Claude Code putting
`env` into the hook's environment, which no test here can see.

Score any file by hand:

```bash
awk -f plugins/signal/lib/score.awk < FILE
```

---

## What it does not touch

- Files the agent writes. Specs, commit messages and pull request text are out.
- Subagent replies. Those go back to the agent that spawned them, not to you.
- Code, paths, commands, links.
- Any language but English.

---

## Tests

```bash
bash plugins/signal/tests/run.sh
```

Runs from a clone of this repo, not from an installed copy: `manifest.sh` reads `bin/repeats.sh` and
both root manifests. Takes about two minutes. Most of that is the audit, which runs the scorer suite
once per mutant.

Four suites: the scorer, the JSON reader, the loop guard, the manifest. The scorer suite proves each
count fires on its own, with the other two inside their lines. Then it breaks the scorer eleven ways
and every break has to turn the suite red. A suite nobody has watched fail is not a suite.

---

*Say less. Mean more.*
