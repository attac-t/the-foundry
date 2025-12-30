#!/bin/bash
# Stop: Prompts working memory update (recitation protocol)
#
# Implements: ground-recitation skill
#
# Purpose: Enforce the WRITE step. Memory must be updated.

MEMORY_DIR="${CLAUDE_MEMORY_DIR:-.claude/memory}"

cat <<EOF
---
**Recite** (ground-recitation protocol)
If you made progress or encountered failures:
→ UPDATE \`$MEMORY_DIR/working.md\`
EOF
