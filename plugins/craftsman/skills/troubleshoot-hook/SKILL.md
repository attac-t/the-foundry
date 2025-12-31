---
name: troubleshoot-hook
description: How to debug the OS Reflexes (Hooks).
---

# Skill: Troubleshoot Hook

> "When the reflexes fail."

## 1. The Principles
*   **Validation**: Regex is tricky. Always test matchers in isolation.
*   **Visibility**: If a hook is silent, it might not be loading. Check `plugin.json` linkage.

## 2. The Implementation
*   **Official Guide**: Use `claude-code-guide` agent to query hook troubleshooting steps.
*   **Debug Mode**: Use `claude-code-guide` to check for verbose/debug flags.

## 3. Common Pitfalls
*   **Orphaned File**: Did you link `hooks.json` in `plugin.json`?
*   **Bad Regex**: Did you escape special characters (e.g., `\.php`)?
