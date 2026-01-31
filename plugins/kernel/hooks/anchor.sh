#!/bin/bash
# UserPromptSubmit: Echoes objective to prevent context drift

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MEMORY_DIR=$("$SCRIPT_DIR/lib/resolve-memory.sh")
MEMORY="$MEMORY_DIR/working.md"

[ ! -f "$MEMORY" ] && exit 0

goal=$("$SCRIPT_DIR/lib/extract-objective.sh" "$MEMORY")
[ -z "$goal" ] && exit 0

branch=$(basename "$MEMORY_DIR")
echo "📎 [$branch] $goal"
