#!/bin/sh
#
# SessionEnd: drop what signal.sh leaves behind — the marker from a block, the note for the brief.
# Losing either costs at most one extra rewrite, so this never fails the session.

root="$(cd "$(dirname "$0")/.." && pwd)"
temp="${TMPDIR:-/tmp}"
payload=$(cat)

# Read the session id, stripped of anything that could climb out of a path.
session() { printf '%s' "$payload" | awk -f "$root/lib/unjson.awk" -v key=session_id | tr -cd 'A-Za-z0-9._-'; }

id=$(session)
[ -n "$id" ] || exit 0

rm -f "$temp/signal-${id}.mark" "$temp/signal-${id}.note" 2>/dev/null
exit 0
