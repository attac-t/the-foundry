---
name: troubleshoot-hook
description: How to debug the OS Reflexes (Hooks).
---

# Skill: Troubleshoot Hook

> "When the reflexes fail."

## Hook Visibility

Not all hooks surface output:

| Event | Visible |
|-------|---------|
| SessionStart | ✅ Yes |
| UserPromptSubmit | ✅ Yes |
| PreCompact | ✅ Yes |
| PostToolUse | ❌ Silent |
| Stop | ❌ Silent (unused) |

**PostToolUse hooks run but don't surface.** Verify via side effects or `Ctrl+O`.

## Common Failures

### Hook Not Firing

1. Check `plugin.json` - is hook registered?
2. Check event type - correct trigger?
3. Check priority - conflicts with other hooks?

### Hook Fires But No Output

If event is `PostToolUse` - this is by design. Output doesn't reach conversation. We don't use `Stop` hooks.

### Regex Not Matching

Bad patterns are the #1 cause. Test in isolation:
```bash
echo "test string" | grep -E "pattern"
```

Escape special characters: `\.php`, `\$`, `\{`

## Debug Steps

1. Verify registration in `plugin.json`
2. Check event type matches intent
3. Test hook script manually: `./hooks/your-hook.sh`
4. For silent hooks, check file side effects
