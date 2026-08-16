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

## Contributing

Seven gates run on every pull request. Run them before you open one:

```bash
sh bin/gates.sh                 # all seven, here
sh bin/gates-in-docker.sh       # all seven on Linux, where `sh` is dash
```

The second is not a convenience. On macOS and under Git Bash `sh` **is** bash and accepts `&>` and
`[[ =~ ]]` without complaint, so neither can fail a bashism — and every runner here opens `#!/bin/sh`.

`bin/agree.sh` holds this table, that workflow and `bin/gates.sh` to the same list. It grades the
seven and is not one of them. `panel` was advertised here and absent from CI for days.

| Gate | Fails when |
|------|------------|
| `frontmatter` | a skill, agent or command is missing the frontmatter that registers it |
| `versions` | `marketplace.json` and a `plugin.json` disagree on a version |
| `repeats` | a sentence appears verbatim in two files — scoped to `panel`, `pest` and `signal` |
| `kernel` | the plugin does not run — checked on Linux, macOS and Windows |
| `signal` | the plugin does not run — checked on Linux, macOS and Windows |
| `floor` | the plugin does not run — checked on Linux, macOS and Windows |
| `panel` | a review round accepts a prior verdict that does not exist, or belongs to another review |

The three runtime gates read `hooks.json` and fire each command the way Claude Code fires it, on each
operating system a user installs on. Only Linux can fail a bashism: `sh` there is dash, where `sh`
on macOS and under Git Bash is really bash and accepts `&>` and `[[ =~ ]]` without complaint. Only
Windows can prove a hook starts without an executable bit, because it is the only one that records
no such bit.

**What they do not check:** that `laravel-ddd`, `laravel-playbook` or `pest` still load, or
that their skills say anything true. Those three ship no code, so there is nothing to run — but
nothing here reads them either. Green means seven gates passed. For those three plugins it does not
mean the change works.

Bump the version in **both** `plugin.json` and `.claude-plugin/marketplace.json` — the manifest is
the one that gets forgotten. Commits use [Commitizen](https://commitizen-tools.github.io/commitizen/)
format.

---

*Forged with intention.*
