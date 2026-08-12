#!/bin/sh
#
# UserPromptSubmit: tell the agent the budget before it writes, not after.
#
# This is the half signal was missing. `Stop` arrives after the reply is written and on screen, so
# blocking there cannot take it back — it adds a second reply beside the first. Nothing ran before
# that. The agent wrote every first draft blind, and the reader got the long answer and the short
# one. Measured on real replies from this repo: 78% of them blocked.
#
# So say the budget first. Then carry the last reply's numbers forward, because a standing rule the
# agent has already broken reads as wallpaper, where "you just ran 288 words against 120" does not.
#
# Plain text on stdout reaches the agent on this event. Nothing here reaches the reader.
#

root="$(cd "$(dirname "$0")/.." && pwd)"
temp="${TMPDIR:-/tmp}"
payload=$(cat)

# Read a value from the hook payload.
value() { printf '%s' "$payload" | awk -f "$root/lib/unjson.awk" -v key="$1"; }

# Get the path to this session's note.
note() { printf '%s/signal-%s.note' "$temp" "${session:-nosession}"; }

#
# Ask the scorer for the budget it will hold the reply to.
#
# Nothing is restated here. A brief that names its own numbers is a second copy of the gate, and the
# copy is the one that goes stale — telling the agent to aim at 120 while the scorer marks against
# something else is worse than saying nothing, because it reads as authoritative.
#
budget() {
  printf '' | awk -f "$root/lib/score.awk" \
    -v long_warn="${SIGNAL_LONG_WARN:-}" \
    -v sent_warn="${SIGNAL_SENT_WARN:-}" \
    -v words_warn="${SIGNAL_WORDS_WARN:-}"
}

# Get a single field from the report.
field() { printf '%s\n' "$report" | awk -F= -v k="$1" '$1 == k { print $2; exit }'; }

# The id lands in a file path, so keep it to characters that cannot climb out of one.
session=$(value session_id | tr -cd 'A-Za-z0-9._-')

# Read the last reply's numbers, then drop them. They answer for one turn only.
last=$(cat "$(note)" 2>/dev/null)
rm -f "$(note)" 2>/dev/null

report=$(budget)

printf 'signal: hold your reply to %s words, no sentence over %s, and long words under %s%%.\n' \
  "$(field words_warn)" "$(field sent_warn)" "$(field long_warn)"
printf 'Code, paths and tables do not count. The bar is a ten-year-old reading it once — see signal:plain-english.\n'

[ -n "$last" ] && printf 'Your last reply came in at %s. Cut harder this time.\n' "$last"

exit 0
