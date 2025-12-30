---
name: craft-hook
description: How to create a new Reflex (Hook) for the OS.
---

# Skill: Craft Hook

> "The Subconscious. Automatic reactions."

## 1. The Principles
*   **Invisible**: A good hook is never noticed. It just *works*.
*   **Non-Blocking**: Hooks should complete quickly. Long tasks belong in agents.
*   **Focused**: One hook, one job. Use matchers to target precisely.

## 2. The Implementation
*   **Official Spec**: Use `claude-code-guide` agent to query hook events and configuration.
*   **Location**: `hooks/hooks.json` (Must be linked in `plugin.json`).

> [!IMPORTANT]
> **Before creating a new hook, use `claude-code-guide` to check for the latest available events.**
> Anthropic may add new hooks. If a new hook is discovered and adopted, update this skill.

## 3. Our Current Hooks (How We Use Them)

| Event          | Our Interpretation                                                      |
|----------------|-------------------------------------------------------------------------|
| `SessionStart` | Memory injection (load `working.md`), persona priming.                  |
| `PreToolUse`   | JIT Learning (e.g., "Controllers must be thin" before editing).         |
| `PostToolUse`  | Architecture guards (e.g., validate Support doesn't import Domain).     |
| `PreCompact`   | Context preservation (protect critical constraints from summarization). |
| `TurnFinished` | Quality gate (remind to verify against `elegance.md`).                  |

## 4. The Pattern
```json
{
  "matcher": "(Controller|Action|DTO)\\.php$",
  "hooks": [{ "type": "command", "command": "echo 'Your advice here'" }]
}
```
*   Use **Regex** for scalable matching. Escape `.` as `\\.`.

## 5. Related Skills
*   **Debugging**: See `troubleshoot-hook`.
*   **Architecture**: See `craft-plugin`.
