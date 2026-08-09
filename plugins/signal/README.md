# signal

> Plain English harness. How to speak.

Agents write too much. This cuts it by ten, and holds the cut with a gate.

---

## Why a hook

An output style asks. A hook refuses.

We tried the style first. It held for three replies, then the old habits came back, and nothing
measured whether it worked. A `Stop` hook gets the finished reply and can hand it back.

---

## The three answers

| Answer | What happens | Cost |
|---|---|---|
| pass | Nothing. You never see the hook | none |
| warn | You get the numbers. The agent does not | none |
| block | The agent gets the numbers and says it again | one turn |

One block per turn. If the rewrite is still over, it ships and you get a note.

`stop_hook_active` says only that *some* stop hook caused the continuation, not which one. So we
write the prompt id to a marker file in your temp directory. We stand down only for that prompt, and
`SessionEnd` deletes the file.

---

## The numbers

| What we count | Pass | Warn | Block |
|---|---|---|---|
| Long words | up to 10% | over 10%, up to 15% | over 15% |
| Longest sentence | up to 20 words | 21 to 30 | over 30 |
| Words in all | up to 120 | 121 to 250 | over 250 |

**Beats** are syllables, counted by vowel groups. `use` is one, `utilise` three.

**Long words** means three beats or more, taken over prose and table cells. Names and paths leave
both sides of the fraction, so a wall of product names cannot water it down.

**Words in all** is prose only. A table is easy to skim, so its cells do not spend the budget.

Sentences end at a full stop or a blank line, never at a line break. Code, paths, commands and links
are never counted.

---

## Why not a reading score

They lean on words per sentence, so line breaks lower the score while the words stay just as hard.
Measured here, a grade-6 bar passed a file using long words seven times as often as a page written
plainly. The scorer still reports `grade`. Nothing gates on it.

## Why no word list

We shipped 209 banned words, then took them out. Hard words are an open set. A list also fires where
it should not: `issue` looks bannable until someone writes "GitHub issue".

So the counts measure shape, and [`signal:plain-english`](skills/plain-english/SKILL.md) judges word
choice against [ASD-STE100](https://www.asd-ste100.org/) and
[ISO 24495-1](https://www.iso.org/standard/78907.html). The skill carries the test.

The trade: short unusual words now pass. `whilst` and `hence` are one beat each, so only the
judgment catches them.

---

## Install

Needs: Claude Code CLI, `bash`, `awk`. No Python, Node or `jq`.

```
/plugin install signal@the-foundry
```

It works on the next reply. There is no style to switch on.

---

## Tune it

| Variable | Ships as |
|---|---|
| `SIGNAL_LONG_WARN` | 10 |
| `SIGNAL_LONG_BLOCK` | 15 |
| `SIGNAL_SENT_WARN` | 20 |
| `SIGNAL_SENT_BLOCK` | 30 |
| `SIGNAL_WORDS_WARN` | 120 |
| `SIGNAL_WORDS_BLOCK` | 250 |

Put them under `env` in a project's `.claude/settings.json`, or in `~/.claude/settings.json` for
every project, or export them in your shell. Only the shell route has a test.

Score a file by hand:

```bash
awk -f plugins/signal/lib/score.awk < FILE
```

---

## Out of scope

Files the agent writes, subagent replies, and any language but English.

---

## Tests

```bash
bash plugins/signal/tests/run.sh
```

Then it breaks the scorer twelve ways, and every break has to turn the suite red. Needs a clone of
this repo, and about two minutes.

---

*Say less. Mean more.*
