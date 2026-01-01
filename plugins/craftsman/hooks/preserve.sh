#!/bin/bash
# PreCompact: Prompts verification before context compression
#
# Distinct from recite.sh:
#   recite  = WRITE prompt ("update if progress")
#   preserve = VERIFY prompt ("confirm memory is complete")
#
# Purpose: Last chance to verify, not to write.

MEMORY_DIR="${CLAUDE_MEMORY_DIR:-.claude/memory}"

cat <<EOF
---
**PRESERVE** (PreCompact)
Context compression imminent.
→ VERIFY \`$MEMORY_DIR/working.md\` contains:
  - Objective (current goal)
  - Constraints (active decisions)
  - Failures (lessons learned)
→ If missing, update NOW. See: ground-recitation
---
EOF
