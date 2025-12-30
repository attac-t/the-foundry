#!/bin/bash
# SessionStart: Loads cognitive RAM (working memory)
#
# "Context is RAM. Filesystem is external memory." — Manus
#
# Purpose: Remember where we left off.

MEMORY_DIR="${CLAUDE_MEMORY_DIR:-.claude/memory}"
MEMORY="$MEMORY_DIR/working.md"

if [ -f "$MEMORY" ]; then
    cat "$MEMORY"
fi
