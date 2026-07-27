#!/bin/bash
# Stop: Checks for incomplete tasks before allowing stop
#
# Uses JSON decision/reason (Stop hook pattern)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MEMORY_DIR=$("$SCRIPT_DIR/lib/resolve-memory.sh")
BLUEPRINT="$MEMORY_DIR/blueprint.md"

# No blueprint? Allow stop.
[ ! -f "$BLUEPRINT" ] && exit 0

# Count in-progress tasks
IN_PROGRESS=$(grep -c '| in-progress |' "$BLUEPRINT" 2>/dev/null) || IN_PROGRESS=0

# No in-progress tasks? Allow stop.
[ "$IN_PROGRESS" -eq 0 ] && exit 0

# Block the stop. Claude must finish, defer, or hand off first.
cat <<EOF
{
  "decision": "block",
  "reason": "Blueprint shows $IN_PROGRESS task(s) in-progress. Either complete them, mark as deferred, or create a handoff before stopping."
}
EOF
