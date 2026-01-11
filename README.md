# The Foundry

A carefully curated collection of Claude Code plugins.

---

## Plugins

| Plugin                                   | Purpose                                                       |
|------------------------------------------|---------------------------------------------------------------|
| [craftsman](plugins/craftsman/README.md) | Stop re-explaining. No drift. A cognitive OS for Claude Code. |

---

## Install

Requires: Claude Code CLI.

```bash
git clone https://github.com/attac-t/the-foundry.git ~/claude-plugins/the-foundry
```

In Claude Code:

```
/plugin marketplace add ~/claude-plugins/the-foundry
/plugin install craftsman@the-foundry
```

Recommended — enable the opinionated voice:

```
/output-style craftsman:craftsman
```

Verify: `/evaluate`

---

*Forged with intention.*
