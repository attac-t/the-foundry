<div align="center">

# The Foundry

**Claude Code plugins that make Claude write code you'd defend in review.**

[![Validate](https://img.shields.io/github/actions/workflow/status/attac-t/the-foundry/validate.yml?branch=main&label=validate&style=flat-square)](https://github.com/attac-t/the-foundry/actions/workflows/validate.yml)
[![License](https://img.shields.io/github/license/attac-t/the-foundry?style=flat-square)](LICENSE)
[![Plugins](https://img.shields.io/badge/plugins-4-blue?style=flat-square)](#the-plugins)
[![Skills](https://img.shields.io/badge/skills-116-blue?style=flat-square)](#the-plugins)

</div>

---

Claude is agreeable. Ask for a bad abstraction and you get a bad abstraction,
implemented well. The Foundry gives it taste, a memory, and the instinct to push
back.

```
Before                              After
──────────────────────────────────  ──────────────────────────────────
Forgets the goal after 50 calls     Objective echoed on every prompt
Invents methods that don't exist    Reads the source before writing
Agrees with your worst idea         "This works, but we can do better"
Loses everything on compaction      Memory outlives the context window
Your patterns get ignored           Patterns activate automatically
```

---

## Install

Requires the [Claude Code CLI](https://code.claude.com/docs).

```bash
git clone https://github.com/attac-t/the-foundry.git ~/claude-plugins/the-foundry
```

Then, in Claude Code:

```
/plugin marketplace add ~/claude-plugins/the-foundry
```

```
/plugin install kernel@the-foundry
```

Verify with `/evaluate`.

Add a stack plugin when you want one. Each pulls in `kernel` on its own, so this
is the whole install:

```
/plugin install laravel-ddd@the-foundry
```

---

## The Plugins

| Plugin | Answers | Skills |
|---|---|---|
| **[kernel](plugins/kernel/README.md)** | How should I think? | 30 |
| **[laravel-ddd](plugins/laravel-ddd/README.md)** | What should I build? | 46 |
| **[laravel-playbook](plugins/laravel-playbook/README.md)** | How do I ship it? | 29 |
| **[pest](plugins/pest/README.md)** | How do I test it? | 11 |

`kernel` is stack-agnostic and does the thinking. The other three are optional,
independent of each other, and each depends on `kernel`.

---

## How It Works

A skill is one unit of judgment in one file. Three kinds:

```
ground-*    How to think     ground-elegance: stop when the code fights you
craft-*     How to build     craft-action: one public method, one responsibility
decide-*    X or Y           decide-dto-vs-array: where the type-safety line sits
```

Skills sitting in a directory get ignored. Scott Spence [measured it][spence]: a
20% baseline, rising to 84% when a hook forces Claude to evaluate each skill
yes/no before it starts work. Committing to an answer is what makes them fire, so
`kernel` ships that hook.

[spence]: https://scottspence.com/posts/how-to-make-claude-code-skills-activate-reliably

Then it keeps the plan somewhere the context window can't reach:

```
.claude/memory/<branch>/
├── working.md      The objective. Re-read on every prompt.
├── blueprint.md    The task ledger.
└── adr/            Decisions, and why.
```

One branch, one memory. Compaction becomes a continuation instead of amnesia.

---

## The Voice

Optional. Turn it on and Claude stops hedging:

```
/output-style kernel:craftsman
```

| Instead of | You get |
|---|---|
| "You might want to consider refactoring this" | "Refactor this." |
| "This could potentially be improved" | "This is slow. Here's why." |
| "It is generally recommended that..." | "Do X." |

---

## Documentation

| Document | Covers |
|---|---|
| [Contributing](CONTRIBUTING.md) | Setup, skill anatomy, the PR workflow |
| [Changelog](CHANGELOG.md) | What changed, per plugin |
| [Security](SECURITY.md) | Reporting, and exactly what the hooks execute |
| [Code of Conduct](CODE_OF_CONDUCT.md) | Critique the code, never the person |
| [ADR-001](docs/adr/ADR-001-plugin-version-single-source.md) | Why a version lives in one file |

Validate a change the way CI does:

```bash
./.github/validate.sh
```

---

## Credits

Standing on the shoulders of:

- [Manus: Context Engineering for AI Agents](https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus) — recitation, filesystem as memory
- [Scott Spence: Reliable Skill Activation](https://scottspence.com/posts/how-to-make-claude-code-skills-activate-reliably) — forced evaluation
- [Sankalp: Claude Code 2.0](https://sankalp.bearblog.dev/my-experience-with-claude-code-20-and-how-to-get-better-at-using-coding-agents/) — agent workflow
- *Laravel Beyond CRUD* by Brent Roose — the domain patterns behind `laravel-ddd`

---

## License

[MIT](LICENSE) © Christian Attard

<div align="center">

*Forged with intention.*

</div>
