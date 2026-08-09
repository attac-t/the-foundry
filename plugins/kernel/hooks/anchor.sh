#!/bin/sh
# UserPromptSubmit: Echoes objective to prevent context drift
#
# The lib scripts are handed to `sh` rather than run as programs. Windows records no executable bit,
# so a hook that depends on one is a hook that does not start there.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MEMORY_DIR=$(sh "$SCRIPT_DIR/lib/resolve-memory.sh")
MEMORY="$MEMORY_DIR/working.md"

[ -f "$MEMORY" ] || exit 0

goal=$(sh "$SCRIPT_DIR/lib/extract-objective.sh" "$MEMORY")
[ -n "$goal" ] || exit 0

branch=$(basename "$MEMORY_DIR")
echo "📎 [$branch] $goal"
