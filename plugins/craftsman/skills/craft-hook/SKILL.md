---
name: craft-hook
description: How to create a new Reflex (Hook) for the OS.
---

# Skill: Craft Hook

> "The Subconscious. Automatic reactions."

## 0. Read The Docs First

> [!CRITICAL]
> **Before writing any hook, read the official guide:**
> https://code.claude.com/docs/en/hooks-guide
>
> This skill captures our learnings, but the official docs are the source of truth.
> Anthropic may add events, change behavior, or deprecate features.

## 1. The Principles

- **Thin**: Hooks trigger, skills explain. Don't implement logic in hooks.
- **Invisible**: A good hook is never noticed. It just *works*.
- **Non-Blocking**: Hooks complete quickly. Long tasks belong in agents.
- **Focused**: One hook, one job. Use matchers to target precisely.

## 2. Context Injection Rules

**Critical**: Not all hooks can prompt Claude. Only these inject output into context:

| Event | Injects to Claude | Use Case |
|-------|-------------------|----------|
| `SessionStart` | ✅ Yes | Initialize context, load memory |
| `UserPromptSubmit` | ✅ Yes | Pre-prompt reinforcement |
| `PreToolUse` | ✅ Yes (on block) | Block + explain why |
| `Stop` | ❌ No | Side effects only |
| `PostToolUse` | ❌ No | Side effects only |
| `PreCompact` | ✅ Yes | Preserve context before compression |
| `Notification` | ❌ No | Side effects only |

**Rule**: If Claude needs to see it, use `SessionStart`, `UserPromptSubmit`, or `PreCompact`.

## 3. Current Implementation

Source of truth: `hooks/hooks.json`

See README lifecycle diagram for hook flow.

## 4. The Pattern

```json
{
  "matcher": "Write|Edit|NotebookEdit",
  "hooks": [{ "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/consider.sh" }]
}
```

- Use **regex matchers** for tool filtering.
- Use `${CLAUDE_PLUGIN_ROOT}` for portable paths.
- Output should reference a skill, not implement logic.

## 5. Implementation

- **Location**: `hooks/hooks.json`
- **Verify**: Check official docs for current event list before creating hooks.

## 6. Related Skills

- **Debugging**: See `troubleshoot-hook`
- **Architecture**: See `craft-plugin`
