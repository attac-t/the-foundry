# signal

> Plain English harness. How to speak.

Agents write too much. This cuts it by ten, and holds the cut with two hooks.

They also build too much — a noun no failing case forced, a fourth guard where one reader was
missing. Same reflex, and the hooks cannot see it, because it is decided before a reply exists. The
`economy` skill asks for both **before** writing; the hooks below catch only what got said.

One speaks before the reply exists and states the budget. One reads what came back. Only the first
can keep a long reply off your screen. `Stop` fires after the reply is written and shown. Handing it
back never takes it away. It puts a second reply beside the first.

---

## What it does

| Answer | What happens | Cost |
|---|---|---|
| pass | Nothing. Last turn's numbers are dropped | none |
| warn | The numbers wait for the agent, and reach it before it writes again | none |
| block | The agent gets them now and says it again | one turn, and you read two replies |

Warn says nothing to you. You are looking at the reply, so its length is not news. The field that
would tell you never reaches the agent. The numbers go to the one who can act on them.

| What we count | Pass | Warn | Block |
|---|---|---|---|
| Long words | up to 10% | over 10%, up to 25% | over 25% |
| Longest sentence | up to 20 words | 21 to 45 | over 45 |
| Words in all | up to 120 | 121 to 600 | over 600 |

**The long-word block needs four of them, and the table cannot show that.** Three long words in a
five-word sentence is 60% and only warns; five in nine is 78% and blocks. A share computed from
almost nothing is not a measurement, and a short reply should not be blocked by one. The warn line
has no such floor — it fires on the share alone.

Warn is where good writing sits. Block is the tail, and it sits far out because it is the only
answer that costs you anything. At 250 words it fired on 78 of every 100 real replies. Each one
handed you the long answer, then the short one. It now sits where the longest 5% of real replies
sit, and 13 in 100 reach it.

**That 78% cannot be credited to the threshold alone.** One commit, `e3cb32a` on 2026-08-12, moved
the block from 250 to 600 *and* added the pre-reply brief. The rate fell afterwards; nothing here can
say which change did it, and both files that quote the number have claimed it for their own.

One block per turn. If the rewrite is still over, it ships and you get a note.

**Beats** are syllables, counted by vowel groups. `use` is one, `utilise` three. **Long words** means
three beats or more, over prose and table cells. Names and paths leave both sides of that fraction.
**Words in all** is prose only, because a table is easy to skim. Sentences end at a full stop or a
blank line, never at a line break. Code, paths, commands and links never count.

Reading scores are not used: line breaks lower them while the words stay hard. No word list ships
either, because hard words are an open set. Word choice is judged by
[`signal:plain-english`](skills/plain-english/SKILL.md) against
[ASD-STE100](https://www.asd-ste100.org/) and [ISO 24495-1](https://www.iso.org/standard/78907.html).
The trade: short unusual words like `whilst` and `hence` pass the counts.

Out of scope: files the agent writes, subagent replies, and any language but English.

Also unscored: every message but the last. A turn can show you three replies and only the third
is counted. `Stop` is handed one message, so nothing can see the others. The brief asks the agent
to hold its answer for the last one. Nothing marks it.

---

## Before the reply exists

Nothing used to tell the agent the budget until it had already broken it. The skill loaded only if
the agent reached for it, and the hook named it only inside a block. Every first draft was written
blind, so the block was not the exception. It was the path.

A `UserPromptSubmit` hook now states the budget on each prompt, and reads out what the last reply
scored. Both go to the agent. Neither reaches you.

The budget is read out of the scorer, never restated. The line the agent aims at is the line it is
marked against.

---

### A third concern, and one line of it is counted

`plain-english` asks *can I understand this?* `economy` asks *did you say only what matters?*
`conclusion` asks **can I tell what is true, and what I need to do?**

A reply leads with its state. A question leads with a recommendation, asks one thing, and names the
reply that settles it. `signal:conclusion` carries the standard, and the brief carries one line of
it before a reply exists.

**Only the question count is scored.** Two questions are two things for a person to answer, so more
than one warns.

Everything else is read by a person. Is the state buried? Were two decisions bundled? Did a bounded
answer flatten an uncertain claim? Each is a judgement, and a check that guessed would be wrong more
often than it helped.

The count is gameable in one direction and not the other. Merge three asks into one sentence and the
sentence-length check fires instead. Split them across replies and nothing here sees it — `Stop`
scores one message.

## Install

Needs: Claude Code CLI, `sh`, `awk`. No Python, Node or `jq`.

```
/plugin install signal@the-foundry
```

It works on the next prompt. There is no style to switch on.

If it cannot run, it says so at the top of the next session. A missing `awk` counts, and so does a
file that did not survive the install. Silence means it is working.

## Where it runs

| Platform | Shell | awk |
|---|---|---|
| macOS | `sh` | the one Apple ships |
| Debian, Ubuntu | `dash` | `mawk` |
| Alpine | BusyBox `ash` | BusyBox |
| Windows | the Git Bash Claude Code starts there | the `awk` Git for Windows ships |

The suite is run on the first three. Windows rests on Git for Windows shipping the same two tools.
Its own [package list](https://github.com/git-for-windows/build-extra/blob/main/make-file-list.sh)
says it does.

## Tune it

| Variable | Ships as |
|---|---|
| `SIGNAL_LONG_WARN` | 10 |
| `SIGNAL_LONG_BLOCK` | 25 |
| `SIGNAL_SENT_WARN` | 20 |
| `SIGNAL_SENT_BLOCK` | 45 |
| `SIGNAL_WORDS_WARN` | 120 |
| `SIGNAL_WORDS_BLOCK` | 600 |

Set a warn line and the brief quotes it back to the agent. The three warn dials are the budget it
is told to hold.

Put them under `env` in `.claude/settings.json`, per project or in your home directory, or export
them in your shell. Score a file by hand with
`awk -f plugins/signal/lib/score.awk < FILE`.

## Tests

```bash
bash plugins/signal/tests/run.sh
```

155 checks, then twenty-one deliberate breaks that must each turn the suite red. Needs a clone of
this repo. Takes a few seconds.

Nine of those breaks target the install, not the scoring. That is where the last one hid. The
shipped hook was not executable, so it died before it read a word. Every other suite stayed green.
Each one called the hook itself, instead of reading how Claude Code is told to call it. So
`tests/install.sh` reads the command out of `hooks/hooks.json` and hands it to a shell.

Four of the nine break the forward correction: at each end, in the middle, and at the turn rule.
Unwired, signal still scores every reply and still blocks the tail. It looks alive while the half
that runs first is gone. A green suite would have said nothing.

One check guards against the way the gate last came apart. Every default lives in `lib/score.awk`.
The hook named them a second time. Raising the block lines in the scorer moved half the gate, and
left the other half shipping the old ones. Nothing was red. No hook may name a default now.

Last comes a check that is neither. The suites block on purpose, and every block writes a file to
your temp directory. Nothing ever came back for those. The cleanup hook runs when a session ends,
and no session ends under a test's name. Thirty had collected there before anyone looked, so the run
now counts them and says so.

---

*Say less. Mean more.*
