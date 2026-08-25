#!/bin/sh
# UserPromptSubmit: Echoes objective to prevent context drift
#
# The lib scripts are handed to `sh`, never run as programs.
# Windows records no executable bit, so a hook that needs
# one is a hook that does not ever start there at all.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MEMORY_DIR=$(sh "$SCRIPT_DIR/lib/resolve-memory.sh")
WORKING_MD="$MEMORY_DIR/working.md"

[ -f "$WORKING_MD" ] || exit 0

goal=$(sh "$SCRIPT_DIR/lib/extract-objective.sh" "$WORKING_MD")
[ -n "$goal" ] || exit 0

# Not always the branch — a run and the bare fallback both land here too.
scope=$(basename "$MEMORY_DIR")
echo "📎 [$scope] $goal"
