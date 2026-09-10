# The Foundry

**Foundry is a protocol, not a tool.** It installs on a repository you already have, and today it
runs on the Claude Code CLI.

Foundry helps software keep improving while people decide what good means.

**[`.foundry/doctrine.md`](.foundry/doctrine.md) holds the full definition** — why Foundry exists,
who it serves and where it is going. Everything below carries it out.

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

**Every `/plugin` line below has a `claude plugin` twin**, for an agent that has no slash commands.
**`/output-style` and `/evaluate` have none** — both are a person's, and an agent cannot reach
either.

### Using Foundry on a repository you already have

Installing kernel buys one thing: **Claude pushes back instead of agreeing.**

```
/plugin marketplace add attac-t/the-foundry
/plugin install kernel@the-foundry
```

Those two, spelled out:

```bash
claude plugin marketplace add attac-t/the-foundry
claude plugin install kernel@the-foundry
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

### Working on Foundry itself

Clone it. The checkout's own `.claude/settings.json` names the marketplace and enables **kernel,
signal and floor** — those three need no install. **Panel, product and the stack plugins still do**,
by either form above.

```bash
git clone https://github.com/attac-t/the-foundry.git
```

---

## When something breaks

An install that fails, a plugin that will not load, anything that does not do what this page says:
[open an issue](https://github.com/attac-t/the-foundry/issues/new/choose). The first form is for
exactly that, and it is the only route a stranger needs.

**One exception, and it matters:** a security problem goes to
[SECURITY.md](SECURITY.md), privately, never as an issue.

## Where the work is

**One board, and it is the front door:** https://github.com/users/attac-t/projects/1

**It is private today, so that link opens for the owner and nobody else.** The issues it draws
from are public, and they are where a stranger starts:
[github.com/attac-t/the-foundry/issues](https://github.com/attac-t/the-foundry/issues).

Its columns are what needs eyes, what is next, what is under review, what only a person can answer,
and what is done.

[`docs/work-system.md`](docs/work-system.md) says where each fact lives, and what the board cannot
do.

---

## What is true here

This tree answers what is true now; GitHub answers how it got here. Goals live only in
[`.foundry/goals.md`](.foundry/goals.md). Issues hold the changes wanted and the open questions, pull
requests hold the reasoning, history keeps every deleted page. **A merged page is read as operative
by the next agent.** So a proposal starts as an issue, and a thinking pass ends as a PR, never in
the tree.

**A merge lands a page. It accepts nothing.** A goal a merged page proposes stays proposed until a
named person says yes, in writing, dated.

**So read [`.foundry/status.md`](.foundry/status.md) before you rely on anything here.** The
doctrine says which promises Foundry means to earn. That page says which ones it can keep today,
and names the ones it cannot.

The one exception stands marked: `docs/rfc/` is an accepted design still being implemented. Its
contracts bind, its revision log is history, and what runs now is each plugin's README.

---

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md). Nineteen gates, and they run before a pull request, not after.

Found a security problem? [SECURITY.md](SECURITY.md) — report it privately, never as an issue.

---

*Forged with intention.*
