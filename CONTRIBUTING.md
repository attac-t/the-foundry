# Contributing

Eight gates. Run them before you open a pull request:

```bash
sh bin/gates.sh                 # all eight, here
sh bin/agree.sh                 # this table, the workflow, gates.sh and every harness file
sh bin/gates.sh linux           # the same eight where `sh` is dash
```

Leave `agree` out of your run and a PR can still go red on a check this file never mentioned — the
drift this file exists to prevent, one level up.

**CI runs more than the three above, not less.** Each of these has no place in `gates.sh` and is
yours to run when it applies:

| | Costs | Run it when |
|---|---|---|
| `sh bin/agree.sh audit` | five minutes | you change what `agree` reads, or how |
| the per-plugin tool check | seconds, in the matrix | a plugin starts reaching for something new |
| three operating systems | a matrix nobody has locally | you touch anything a suite runs |

The last one is the gap no local run closes. **A green tree here says nothing about macOS**, and has
not since the billing lapsed.

**A green gate is not a working gate.** `bash bin/breaks.sh` drives each one against a tree that
breaks it and prints what was caught. It is not in `gates.sh` and never will be: it makes the tree red
on purpose, and a gate grading the gates is a loop nothing outside it can check.

Run it when you change what a gate grades. Two checks here were vacuous for weeks, and a bad break
looks exactly like a blind gate — #351 holds why.

The second is not a convenience. On macOS and under Git Bash `sh` **is** bash and accepts `&>` and
`[[ =~ ]]` without complaint, so neither can fail a bashism — and every runner here opens `#!/bin/sh`.

`bin/agree.sh` holds this table, that workflow and `bin/gates.sh` to the same list. It grades the
eight and is not one of them. `panel` was advertised here and absent from CI for days.

It holds one more thing: **every harness file names the same rules.** Claude reads `CLAUDE.md` and
Codex reads `AGENTS.md`, so `bin/project.sh` writes the table into both from `.claude/rules` itself.
Edit a rule, then run it — a row typed by hand into one file is the drift nothing else would see.

| Gate | Fails when |
|------|------------|
| `frontmatter` | a skill, agent or command is missing the frontmatter that registers it |
| `versions` | a plugin the manifest lists cannot say what version it is |
| `repeats` | a sentence appears verbatim in two files — scoped to `panel`, `pest` and `signal` |
| `shell` | shipped shell takes an `else`, or a function body passes 40 lines |
| `taper` | a three-line comment paragraph does not narrow by three, and nothing names it |
| `comments` | a public comment carrying the seam's marker breaks a rule the seam applies |
| `kernel` | the plugin does not run — checked on Linux, macOS and Windows |
| `signal` | the plugin does not run — checked on Linux, macOS and Windows |
| `floor` | the plugin does not run — checked on Linux, macOS and Windows |
| `panel` | a review round accepts a prior verdict that does not exist, or belongs to another review |

**A gate that could not read its inputs exits 3, and says so.** It never reports a pass over an
empty set — nothing to check is not a clean check. `bin/shell.sh`'s header holds the codes.

`shell` reads `plugins/*/bin`, `lib` and `hooks` — never `tests/`, which are bash on purpose. It
gates a number, not craft-sh's rule: length is the *signal* that another function is merited, and no
exit code reads a signal. Two bodies in `floor` are past 40 already and named in the gate as debt,
so the bar stays real for everything written after them.

The three runtime gates read `hooks.json` and fire each command the way Claude Code fires it, on each
operating system a user installs on. Only Linux can fail a bashism: `sh` there is dash, where `sh`
on macOS and under Git Bash is really bash and accepts `&>` and `[[ =~ ]]` without complaint. Only
Windows can prove a hook starts without an executable bit, because it is the only one that records
no such bit.

**What they do not check:** that `laravel-ddd`, `laravel-playbook` or `pest` still load, or
that their skills say anything true. Those three ship no code, so there is nothing to run — but
nothing here reads them either. Green means ten gates passed. For those three plugins it does not
mean the change works.

Bump the version in the plugin's own `plugin.json`, and there only. `marketplace.json` names
plugins and where they live, and carries no version — a second copy made one shared line every
branch edits, so plugin work collided for packaging reasons. Commits use [Commitizen](https://commitizen-tools.github.io/commitizen/)
format.

---

## Your machine

A clone brings `kernel`, `signal` and `floor` with it — `.claude/settings.json` names the marketplace
and enables all three. The rules in `.claude/rules/` assume them, and a skill that is not installed is
a rule pointing at nothing.

`signal` is the one that is easy to skip and expensive to. It states a word budget before each reply
rather than marking one afterwards. This used to cite 78% of first drafts blocked without it; that
figure belongs to a commit which also tripled the block threshold, so it measures neither change on
its own. Signal's README carries the arithmetic.
