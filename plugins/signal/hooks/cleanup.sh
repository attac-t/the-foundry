#!/bin/sh
#
# SessionEnd: drop the two files signal.sh writes — the marker it leaves when it blocks, and the
# note it leaves for the next turn's brief.
# Losing either costs at most one extra rewrite, so this never fails the session.

root="$(cd "$(dirname "$0")/.." && pwd)"
payload=$(cat)

# Read the session id, stripped of anything that could climb out of a path.
session() { printf '%s' "$payload" | awk -f "$root/lib/unjson.awk" -v key=session_id | tr -cd 'A-Za-z0-9._-'; }

id=$(session)
[ -n "$id" ] || exit 0

rm -f "${TMPDIR:-/tmp}/signal-${id}.mark" "${TMPDIR:-/tmp}/signal-${id}.note" 2>/dev/null
exit 0
