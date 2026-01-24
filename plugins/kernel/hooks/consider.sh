#!/bin/bash
# PostToolUse: Prompts ADR consideration after file modifications
#
# Thin hook → points to craft-adr skill
#
# Purpose: Remind that architectural decisions should be recorded.

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.pathInProject // ""')

# Skip non-architectural files
if echo "$FILE" | grep -qE '(^tests?/|\.test\.|\.spec\.|\.md$|\.json$|\.ya?ml$|\.env)'; then
    exit 0
fi

cat <<'EOF'
---
**Consider** (craft-adr)
You modified code. If this involved:
→ Pattern choice → ADR
→ Package choice → ADR
→ Schema design → ADR
See: craft-adr skill
---
EOF
