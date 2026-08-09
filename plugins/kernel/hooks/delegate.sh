#!/bin/sh
# UserPromptSubmit: Reminds architect to assess delegation when blueprint exists
#
# Thin hook → points to ground-delegation skill
#
# `$0`, not `${BASH_SOURCE[0]}`. The array subscript is a bash extension, and every other shell
# stops at "Bad substitution" before the hook reads a thing.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MEMORY_DIR=$(sh "$SCRIPT_DIR/lib/resolve-memory.sh")

# Only fire if blueprint exists
BLUEPRINT="$MEMORY_DIR/blueprint.md"
[ -f "$BLUEPRINT" ] || exit 0

# Check if any agent tasks are pending or if we should reassess
cat <<'EOF'
---
**Delegation Check** (ground-delegation)

Blueprint active. Before starting work:
1. Any `agent` tasks ready to delegate in parallel?
2. Any `pending` tasks that should be reassessed as `agent`?

Justify if keeping delegatable work as `self`.
EOF
