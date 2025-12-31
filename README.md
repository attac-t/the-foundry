# The Foundry

A carefully curated collection of Claude Code plugins.

---

## Plugins

| Plugin                                   | Purpose                                                       |
|------------------------------------------|---------------------------------------------------------------|
| [craftsman](plugins/craftsman/README.md) | Stop re-explaining. No drift. A cognitive OS for Claude Code. |

---

## Install

### Web & Android Sessions (Auto-Install)

For Claude Code web and Android sessions, the plugin **installs automatically** when you clone this repository:

```bash
git clone https://github.com/attac-t/the-foundry.git
cd the-foundry
```

The `.claude/settings.json` configuration handles:
- Marketplace registration from GitHub
- Automatic plugin enablement
- SessionStart hooks initialization

Verify: `/evaluate`

### Local CLI (Manual Install)

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

## Configuration

### Auto-Install Architecture

The `.claude/settings.json` file enables automatic plugin installation in web and Android sessions:

- **`extraKnownMarketplaces`**: Registers the-foundry marketplace from GitHub
- **`enabledPlugins`**: Auto-enables craftsman@the-foundry on session start
- **`hooks`**: SessionStart, UserPromptSubmit, and Stop hooks using `$CLAUDE_PLUGIN_craftsman_the_foundry` path

This configuration is version-controlled and works automatically in remote sessions.

### The Hook Problem

Plugin hooks don't reach Claude ([#12151](https://github.com/anthropics/claude-code/issues/12151)). The hooks are configured in `.claude/settings.json` instead, using the `$CLAUDE_PLUGIN_<name>_<marketplace>` environment variable that Claude Code provides when plugins are enabled.

---

*Forged with intention.*
