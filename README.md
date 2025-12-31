# The Foundry

A carefully curated collection of Claude Code plugins.

---

## Plugins

| Plugin                                   | Purpose                                                       |
|------------------------------------------|---------------------------------------------------------------|
| [craftsman](plugins/craftsman/README.md) | Stop re-explaining. No drift. A cognitive OS for Claude Code. |

---

## Install

Requires: Claude Code CLI, `jq`.

```bash
git clone https://github.com/attac-t/the-foundry.git ~/claude-plugins/the-foundry
```

From your project:

```bash
~/claude-plugins/the-foundry/setup.sh
```

In Claude Code:

```
/plugin marketplace add ~/claude-plugins/the-foundry
/plugin install craftsman@the-foundry
```

Verify: `/evaluate`

---

## The Hook Problem

Plugin hooks don't reach Claude ([#12151](https://github.com/anthropics/claude-code/issues/12151)). The `setup.sh` script writes them to `.claude/settings.json` instead.

Add `.claude/settings.json` to your `.gitignore`—it contains local paths.

---

*Forged with intention.*
