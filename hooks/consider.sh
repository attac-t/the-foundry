#!/bin/bash
# PostToolUse: Prompts ADR consideration after architectural changes
#
# Implements: craft-adr skill
#
# Purpose: Architectural decisions must be recorded.

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.pathInProject // ""')

if echo "$FILE" | grep -qE '^(domain|support)/'; then
    cat <<'EOF'
---
**Consider** (craft-adr check)
You modified architectural code. Record if:
- Pattern choice → ADR
- Package choice → ADR
- Schema design → ADR
Location: `docs/{domain}/ADR/`
EOF
fi
