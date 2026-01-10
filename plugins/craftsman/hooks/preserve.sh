#!/bin/bash
# PreCompact: Prompts verification before context compression
# Branch-aware via lib/resolve-memory.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MEMORY_DIR=$("$SCRIPT_DIR/lib/resolve-memory.sh")

cat <<EOF
---
**PRESERVE** (PreCompact)
Context compression imminent.
→ VERIFY \`$MEMORY_DIR/working.md\` contains:
  - Objective (current goal)
  - Constraints (active decisions)
  - Failures (lessons learned)
→ VERIFY \`$MEMORY_DIR/blueprint.md\` contains:
  - Current task status
  - Deferred items (if any)
  - Changes (if scope evolved)
→ If missing, update NOW. See: ground-recitation

⛔ **BLOCKING**: Do not proceed with compaction until verified.
EOF
