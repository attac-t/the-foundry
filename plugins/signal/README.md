# signal

> Plain English harness. How to speak.

Agents write too much. This cuts it by ten, and holds the cut with a gate.

An output style asks. A `Stop` hook gets the finished reply and can hand it back.

---

## What it does

| Answer | What happens                                 | Cost     |
|--------|----------------------------------------------|----------|
| pass   | Nothing. You never see the hook              | none     |
| warn   | You get the numbers. The agent does not      | none     |
| block  | The agent gets the numbers and says it again | one turn |

One block per turn. If the rewrite is still over, it ships and you get a note.

| What we count    | Pass           | Warn                | Block    |
|------------------|----------------|---------------------|----------|
| Long words       | up to 10%      | over 10%, up to 15% | over 15% |
| Longest sentence | up to 20 words | 21 to 30            | over 30  |
| Words in all     | up to 120      | 121 to 250          | over 250 |

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

---

## Install

Needs: Claude Code CLI, `sh`, `awk`. No Python, Node or `jq`.

```
/plugin install signal@the-foundry
```

It works on the next reply. There is no style to switch on.

If it cannot run, it says so at the top of the next session. A missing `awk` counts, and so does a
file that did not survive the install. Silence means it is working.

## Where it runs

| Platform       | Shell                                 | awk                             |
|----------------|---------------------------------------|---------------------------------|
| macOS          | `sh`                                  | the one Apple ships             |
| Debian, Ubuntu | `dash`                                | `mawk`                          |
| Alpine         | BusyBox `ash`                         | BusyBox                         |
| Windows        | the Git Bash Claude Code starts there | the `awk` Git for Windows ships |

The suite is run on the first three. Windows rests on Git for Windows shipping the same two tools.
Its own [package list](https://github.com/git-for-windows/build-extra/blob/main/make-file-list.sh)
says it does.

## Tune it

| Variable             | Ships as |
|----------------------|----------|
| `SIGNAL_LONG_WARN`   | 10       |
| `SIGNAL_LONG_BLOCK`  | 15       |
| `SIGNAL_SENT_WARN`   | 20       |
| `SIGNAL_SENT_BLOCK`  | 30       |
| `SIGNAL_WORDS_WARN`  | 120      |
| `SIGNAL_WORDS_BLOCK` | 250      |

Put them under `env` in `.claude/settings.json`, per project or in your home directory, or export
them in your shell. Score a file by hand with
`awk -f plugins/signal/lib/score.awk < FILE`.

## Tests

```bash
bash plugins/signal/tests/run.sh
```

114 checks, then seventeen deliberate breaks that must each turn the suite red. Needs a clone of
this repo. Takes a few seconds.

Five of those breaks target the install, not the scoring. That is where the last one hid. The
shipped hook was not executable, so it died before it read a word. Every other suite stayed green.
Each one called the hook itself, instead of reading how Claude Code is told to call it. So
`tests/install.sh` reads the command out of `hooks/hooks.json` and hands it to a shell.

Last comes a check that is neither. The suites block on purpose, and every block writes a file to
your temp directory. Nothing ever came back for those. The cleanup hook runs when a session ends,
and no session ends under a test's name. Thirty had collected there before anyone looked, so the run
now counts them and says so.

---

*Say less. Mean more.*
