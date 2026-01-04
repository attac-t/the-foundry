#!/bin/bash
# UserPromptSubmit: Echoes context and checks alignment
# Branch-aware via lib/resolve-memory.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MEMORY_DIR=$("$SCRIPT_DIR/lib/resolve-memory.sh")
MEMORY="$MEMORY_DIR/working.md"

[ ! -f "$MEMORY" ] && exit 0

goal=$(grep '^\*\*Objective\*\*:' "$MEMORY" | sed 's/\*\*Objective\*\*: //')
[ -z "$goal" ] && exit 0
[ "$goal" = "[What are we building/fixing?]" ] && exit 0

# Extract branch from memory path (last component)
branch=$(echo "$MEMORY_DIR" | sed 's|.*/||')

echo "📎 [$branch] $goal — ⛔ Misaligned? STOP."
