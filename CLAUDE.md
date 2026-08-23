# The Foundry

@README.md

---

## Rules

This file routes. It holds no rules of its own.

Everything in `.claude/rules/` loads on its own, because none of it is path-scoped. If a rule is not
in your context, read it.

| Rule | Owns |
|---|---|
| [closing](.claude/rules/closing.md) | when a GitHub issue may be closed — every box, or say why not |
| [economy](.claude/rules/economy.md) | saying and doing more with less, decided before writing |
| [guidance](.claude/rules/guidance.md) | which file a new instruction belongs in — a rule, a skill or a README |
| [identity](.claude/rules/identity.md) | who the record says did the work — git, and which `gh` writes |
| [writing](.claude/rules/writing.md) | issues, pull requests, RFCs, READMEs, commits, comments |
| [plugins](.claude/rules/plugins.md) | version bumps, stack plugins, the dependency contract |
| [shell](.claude/rules/shell.md) | reading `craft-sh` before a shipped script is edited |

Add a rule or a skill rather than adding to this file — `guidance` decides which. One subject per
file, named for the subject.
