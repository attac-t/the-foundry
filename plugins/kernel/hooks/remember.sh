#!/bin/sh
# SessionStart: Loads working.md, blueprint.md, and latest handoff

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MEMORY_DIR=$(sh "$SCRIPT_DIR/lib/resolve-memory.sh")

# Get the newest handoff, or nothing. Names lead with a sequence number, so the last one sorts first.
latest_handoff() {
    find "$MEMORY_DIR/handoffs" -maxdepth 1 -name '*.md' -type f 2>/dev/null | sort -r | head -1
}

WORKING_MD="$MEMORY_DIR/working.md"
[ -f "$WORKING_MD" ] && cat "$WORKING_MD"

BLUEPRINT="$MEMORY_DIR/blueprint.md"
[ -f "$BLUEPRINT" ] && { echo ""; cat "$BLUEPRINT"; }

HANDOFF=$(latest_handoff)
if [ -n "$HANDOFF" ]; then
    echo ""
    echo "---"
    echo "**Latest Handoff** ($(basename "$HANDOFF")):"
    echo ""
    cat "$HANDOFF"
fi

exit 0
