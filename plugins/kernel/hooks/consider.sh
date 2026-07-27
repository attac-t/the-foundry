#!/bin/bash
# PostToolUse: Prompts ADR consideration after code changes
#
# Uses JSON additionalContext (PostToolUse stdout doesn't reach Claude)

# Without jq we cannot read the filename, so we cannot skip tests, docs, or
# config. Firing on everything is worse than staying quiet.
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.pathInProject // ""')

# Skip non-code files (tests, docs, config)
echo "$FILE" | grep -qE '((^|/)tests?/|\.test\.|\.spec\.|\.md$|\.json$|\.ya?ml$|\.env)' && exit 0

# JSON output for PostToolUse context injection
cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "**Consider**: You modified code. If this involved a pattern choice, package choice, or schema design → run `craft-adr`."
  }
}
EOF
