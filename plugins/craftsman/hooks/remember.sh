#!/bin/bash
# SessionStart: Loads cognitive RAM (working memory)
# Branch-aware via lib/resolve-memory.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MEMORY_DIR=$("$SCRIPT_DIR/lib/resolve-memory.sh")
MEMORY="$MEMORY_DIR/working.md"

[ -f "$MEMORY" ] && cat "$MEMORY"
