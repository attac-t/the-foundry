# The Foundry

@README.md

---

## Rules

This file routes. It holds no rules of its own.

Everything in `.claude/rules/` loads on its own, because none of it is path-scoped. If a rule is not
in your context, read it.

| Rule | Owns |
|---|---|
| [writing](.claude/rules/writing.md) | issues, pull requests, RFCs, READMEs, commits, comments |
| [plugins](.claude/rules/plugins.md) | version bumps, stack plugins, the dependency contract |

Add a rule rather than adding to this file. One subject per file, named for the subject.
