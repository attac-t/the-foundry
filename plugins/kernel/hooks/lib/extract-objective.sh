#!/bin/bash
# Extracts objective from working.md
#
# Matches: **Objective**: text
#
# Usage: extract-objective.sh <path-to-working.md>
# Output: objective text (or empty)

WORKING_MD="$1"
[ ! -f "$WORKING_MD" ] && exit 0

goal=$(grep '^\*\*Objective\*\*:' "$WORKING_MD" | sed 's/\*\*Objective\*\*:[[:space:]]*//' | head -1)

# Skip placeholders like [TBD]
[[ "$goal" =~ ^\[.*\]$ ]] && exit 0

echo "$goal"
