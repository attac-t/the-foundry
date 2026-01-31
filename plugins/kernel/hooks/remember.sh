#!/bin/bash
# SessionStart: Loads working.md, blueprint.md, and latest handoff

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MEMORY_DIR=$("$SCRIPT_DIR/lib/resolve-memory.sh")

# Load working memory
MEMORY="$MEMORY_DIR/working.md"
[ -f "$MEMORY" ] && cat "$MEMORY"

# Load blueprint
BLUEPRINT="$MEMORY_DIR/blueprint.md"
[ -f "$BLUEPRINT" ] && echo "" && cat "$BLUEPRINT"

# Load latest handoff (if exists)
HANDOFF_DIR="$MEMORY_DIR/handoffs"
if [ -d "$HANDOFF_DIR" ]; then
    LATEST_HANDOFF=$(find "$HANDOFF_DIR" -maxdepth 1 -name '*.md' -type f 2>/dev/null | sort -r | head -1)
    if [ -n "$LATEST_HANDOFF" ] && [ -f "$LATEST_HANDOFF" ]; then
        echo ""
        echo "---"
        echo "**Latest Handoff** ($(basename "$LATEST_HANDOFF")):"
        echo ""
        cat "$LATEST_HANDOFF"
    fi
fi
