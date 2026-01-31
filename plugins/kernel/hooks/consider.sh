#!/bin/bash
# PostToolUse: Prompts ADR consideration after code changes
#
# Uses JSON additionalContext (PostToolUse stdout doesn't reach Claude)

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.pathInProject // ""')

# Skip non-code files (tests, docs, config)
echo "$FILE" | grep -qE '(^tests?/|\.test\.|\.spec\.|\.md$|\.json$|\.ya?ml$|\.env)' && exit 0

# JSON output for PostToolUse context injection
cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "**Consider**: You modified code. If this involved a pattern choice, package choice, or schema design → run `craft-adr`."
  }
}
EOF
