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

## What is true here

This tree answers what is true now; GitHub answers how it got here. Issues hold goals and open
questions, pull requests hold the reasoning, history keeps every deleted page. A merged page is
read as operative by the next agent — so a proposal starts as an issue, and a thinking pass ends
as a PR, not in the tree.

The one exception stands marked: `docs/rfc/` is an accepted design still being implemented. Its
contracts bind, its revision log is history, and what runs now is each plugin's README.

---

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md). Eight gates, and they run before a pull request, not after.

Found a security problem? [SECURITY.md](SECURITY.md) — report it privately, never as an issue.

---

*Forged with intention.*
