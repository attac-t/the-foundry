# Two hook shapes, whole

### PostToolUse JSON Pattern

```bash
cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Your message to Claude here"
  }
}
EOF
```

### Stop Hook Pattern (Prompt-Based)

```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "prompt",
        "prompt": "Check if task is complete. Return {\"ok\": false, \"reason\": \"...\"} to continue."
      }]
    }]
  }
}
```

