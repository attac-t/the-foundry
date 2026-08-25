#!/bin/sh
# Extracts objective from working.md
#
# Matches: Objective: text
#
# Usage: extract-objective.sh <path-to-working.md>
# Output: objective text (or empty)

WORKING_MD="$1"
[ -f "$WORKING_MD" ] || exit 0

goal=$(grep '^\*\*Objective\*\*:' "$WORKING_MD" | sed 's/\*\*Objective\*\*:[[:space:]]*//' | head -1)

# Skip placeholders like [TBD]. `case`, never `[[ =~ ]]` — dash
# does not parse that one at all. It fails on the bracket long
# before it ever gets as far as reading the pattern at all.
case "$goal" in
  "["*"]") exit 0 ;;
esac

echo "$goal"
