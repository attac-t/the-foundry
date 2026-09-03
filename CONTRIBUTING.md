# Contributing

Ten gates. Run them before you open a pull request:

```bash
sh bin/gates.sh                 # all ten, here
sh bin/agree.sh                 # this table, the workflow, gates.sh and every harness file
sh bin/gates.sh linux           # the same ten where `sh` is dash
```

Leave `agree` out of your run and a PR can still go red on a check this file never mentioned — the
drift this file exists to prevent, one level up.

## On Windows, run them in WSL from the Linux disk

**Measured 2 September 2026, one laptop, one commit.**

| | Git Bash | WSL on ext4 |
|---|---|---|
| floor's model suite | **4,611 s** | **49 s** |
| the whole floor gate | never finished | **19 m** |
| `open`, per call | 9,506 ms | 214 ms |

The process count is the same on both. Git Bash charges about 80 ms to start one and Linux
charges one, so the bill is cygwin process start, not this code.

```bash
git clone /mnt/c/path/to/the-foundry /tmp/foundry   # ext4, never /mnt/c
cd /tmp/foundry && sh bin/gates.sh
```

**Clone to the Linux disk.** `/mnt/c` is a network-shaped filesystem and gives most of the
speed back.

**It also runs checks Windows cannot.** NTFS records no executable bit and no read bit, keeps no
symlink, and ignores `chmod`. A check that reads one of those reports *unrunnable* and stands down.

**So the pass count is not comparable across platforms.** Measured 3 September on one laptop:

| suite | Git Bash | WSL on ext4 |
|---|---|---|
| install | 25 passed, 1 n/a | 30 passed, 0 n/a |
| host | 44 passed | 45 passed |
| say | 36 passed | 36 passed |

One `n/a` line hid five passes in install, because the check it guards sits in a loop. **`n/a`
counts lines, never checks**, so the two columns cannot be reconciled by adding it back.

Read `failed` and `skipped` instead. Both must be zero on every platform, and both mean the same
thing everywhere.

The model suite is not in that table. Counting it on Git Bash costs 77 minutes, and nobody has.

Two real faults hid behind all this for months. Panel could not start on Linux at all, and a
shipped script carried no executable bit.

**This is not a fix for macOS.** WSL is how a Windows machine reaches Linux. A gate that only
runs where its author sits still grades one platform, and that is the fault it just found.

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
ten and is not one of them. `panel` was advertised here and absent from CI for days.

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

**What they do not check:** that `laravel-ddd`, `laravel-playbook`, `pest` or `product` still load,
or that their skills say anything true. Those four ship no code, so there is nothing to run — but
nothing here reads them either. Green means ten gates passed. For those four plugins it does not
mean the change works.

Bump the version in the plugin's own `plugin.json`, and there only. `marketplace.json` carries one
`version`, and it is **the marketplace's own** — it names plugins and where they live, never what
version each is at. A second copy made one shared line every branch edits, so plugin work collided
for packaging reasons. Commits use [Commitizen](https://commitizen-tools.github.io/commitizen/)
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
