#!/bin/bash
# Stop: Echoes the current objective (anchoring)
#
# "Constantly rewriting todo lists pushes the global plan
#  into recent attention span." — Manus
#
# Purpose: Keep the goal visible. Prevent drift.

MEMORY_DIR="${CLAUDE_MEMORY_DIR:-.claude/memory}"
MEMORY="$MEMORY_DIR/working.md"

if [ -f "$MEMORY" ]; then
    goal=$(grep '^\*\*Goal\*\*:' "$MEMORY" | sed 's/\*\*Goal\*\*: //')
    if [ -n "$goal" ] && [ "$goal" != "[What are we building/fixing?]" ]; then
        echo "📎 $goal"
    fi
fi
