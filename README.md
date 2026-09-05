# The Foundry

Foundry helps software keep improving while people decide what good means.

**Start with [`.foundry/doctrine.md`](.foundry/doctrine.md).** It says what Foundry is, why it
exists, who it serves and where it is going. Everything below carries it out.

The plugins ship it, and each one is useful alone.

---

## Plugins

| Plugin | Purpose |
|--------|---------|
| [kernel](plugins/kernel/README.md) | Cognitive OS. How to think. |
| [panel](plugins/panel/README.md) | Adversarial agent teams. How to verify. |
| [product](plugins/product/README.md) | Beliefs against reality. What to question. |
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

Have work judged by something that did not write it:

```
/plugin install panel@the-foundry
```

Keep what the repository believes in contact with what is true:

```
/plugin install product@the-foundry
```

Enable the opinionated voice:

```
/output-style kernel:craftsman
```

Check kernel is live: `/evaluate`. It tests kernel's hooks, memory and agents — **never that
the other plugins installed.**

## Where the work is

**One board, and it is the front door:** https://github.com/users/attac-t/projects/1

**It is private today, so that link opens for the owner and nobody else.** The issues it draws
from are public, and they are where a stranger starts.

It shows what needs eyes, what is next, what is under review, what only a person can answer, and
what is done. [`docs/work-system.md`](docs/work-system.md) says where each fact lives and what the
board cannot do.

---

## What is true here

This tree answers what is true now; GitHub answers how it got here. Goals live only in
[`.foundry/goals.md`](.foundry/goals.md). Issues hold the changes wanted and the open questions, pull
requests hold the reasoning, history keeps every deleted page. A merged page is read as operative by
the next agent — so a proposal starts as an issue, and a thinking pass ends as a PR, not in the tree.

**A merge lands a page. It accepts nothing.** A goal a merged page proposes stays proposed until a
named person says yes, in writing, dated.

The one exception stands marked: `docs/rfc/` is an accepted design still being implemented. Its
contracts bind, its revision log is history, and what runs now is each plugin's README.

---

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md). Eleven gates, and they run before a pull request, not after.

Found a security problem? [SECURITY.md](SECURITY.md) — report it privately, never as an issue.

---

*Forged with intention.*
