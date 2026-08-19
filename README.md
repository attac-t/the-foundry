# The Foundry

A curated collection of Claude Code plugins.

---

## Plugins

| Plugin | Purpose |
|--------|---------|
| [kernel](plugins/kernel/README.md) | Cognitive OS. How to think. |
| [panel](plugins/panel/README.md) | Adversarial agent teams. How to verify. |
| [signal](plugins/signal/README.md) | Plain English harness. How to speak. |
| [floor](plugins/floor/README.md) | Runs and workspaces. Where work happens. |
| [laravel-ddd](plugins/laravel-ddd/README.md) | Laravel DDD patterns. What to build. |
| [laravel-playbook](plugins/laravel-playbook/README.md) | Package author's playbook. How to ship. |
| [pest](plugins/pest/README.md) | Pest v3 syntax. How to test. |

---

## Install

Requires: Claude Code CLI.

```bash
git clone https://github.com/attac-t/the-foundry.git ~/claude-plugins/the-foundry
```

In Claude Code:

```
/plugin marketplace add ~/claude-plugins/the-foundry
/plugin install kernel@the-foundry
```

Add stack plugins as needed:

```
/plugin install laravel-ddd@the-foundry
/plugin install laravel-playbook@the-foundry
/plugin install pest@the-foundry
```

Hold every reply to plain English:

```
/plugin install signal@the-foundry
```

Give work a home outside the repo it changes:

```
/plugin install floor@the-foundry
```

Enable the opinionated voice:

```
/output-style kernel:craftsman
```

Verify the install: `/evaluate`

---

## What is true here

This tree answers what is true now; GitHub answers how it got here. Issues hold goals and open
questions, pull requests hold the reasoning, history keeps every deleted page. A merged page is
read as operative by the next agent — so a proposal starts as an issue, and a thinking pass ends
as a PR, not in the tree.

The one exception stands marked: `docs/rfc/` is an accepted design still being implemented. Its
contracts bind, its revision log is history, and what runs now is each plugin's README.

---

## Contributing

Eight gates. Run them before you open a pull request:

```bash
sh bin/gates.sh                 # all eight, here
sh bin/agree.sh                 # this table, the workflow and gates.sh name the same eight
sh bin/gates.sh linux           # the same eight where `sh` is dash
```

CI runs the first two. Leave `agree` out of your run and a PR can still go red on a check the README
never mentioned — the drift this file exists to prevent, one level up.

The second is not a convenience. On macOS and under Git Bash `sh` **is** bash and accepts `&>` and
`[[ =~ ]]` without complaint, so neither can fail a bashism — and every runner here opens `#!/bin/sh`.

`bin/agree.sh` holds this table, that workflow and `bin/gates.sh` to the same list. It grades the
eight and is not one of them. `panel` was advertised here and absent from CI for days.

| Gate | Fails when |
|------|------------|
| `frontmatter` | a skill, agent or command is missing the frontmatter that registers it |
| `versions` | `marketplace.json` and a `plugin.json` disagree on a version |
| `repeats` | a sentence appears verbatim in two files — scoped to `panel`, `pest` and `signal` |
| `shell` | shipped shell takes an `else`, or a function body passes 40 lines |
| `kernel` | the plugin does not run — checked on Linux, macOS and Windows |
| `signal` | the plugin does not run — checked on Linux, macOS and Windows |
| `floor` | the plugin does not run — checked on Linux, macOS and Windows |
| `panel` | a review round accepts a prior verdict that does not exist, or belongs to another review |

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
nothing here reads them either. Green means eight gates passed. For those three plugins it does not
mean the change works.

Bump the version in **both** `plugin.json` and `.claude-plugin/marketplace.json` — the manifest is
the one that gets forgotten. Commits use [Commitizen](https://commitizen-tools.github.io/commitizen/)
format.

---

*Forged with intention.*
