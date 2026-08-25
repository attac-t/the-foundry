#!/bin/sh
#
# UserPromptSubmit: tell the agent the budget before it writes, not after.
#
# The half signal was missing. `Stop` arrives too late to keep a long reply off the screen, so every
# first draft was written blind and the block was the path rather than the exception. This is the
# only moment that can help.
#
# It used to claim 78% here. That commit also tripled the block threshold, so the number measures the
# pair and not this hook — signal's README says so where the arithmetic lives.
#
# Then where the answer goes. `Stop` is handed one message, so a turn that answered twice scores as
# one reply and passes. Nothing can mark the shape, so this is the only place it can be asked for.
#
# Then the last reply's numbers, because a standing rule the agent has already broken reads as
# wallpaper, where "you just ran 288 words against 120" does not.
#
# Plain text on stdout reaches the agent on this event. Nothing here reaches the reader.
#
# No `set -e`: most turns leave no note, and the read that finds none would end the hook before it
# states the budget.
#

root="$(cd "$(dirname "$0")/.." && pwd)"
temp="${TMPDIR:-/tmp}"
payload=$(cat)

# Read a value from the hook payload.
value() { printf '%s' "$payload" | awk -f "$root/lib/unjson.awk" -v key="$1"; }

# Get the path to this session's note.
notefile() { printf '%s/signal-%s.note' "$temp" "${session:-nosession}"; }

# Ask the scorer for the budget it will mark against. Naming it here instead would be a second copy
# of the gate, and a brief that aims the agent at a line nobody marks is worse than no brief.
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
last=$(cat "$(notefile)" 2>/dev/null)
rm -f "$(notefile)" 2>/dev/null

report=$(budget)

printf 'signal: hold your reply to %s words, no sentence over %s, and long words under %s%%.\n' \
  "$(field words_warn)" "$(field sent_warn)" "$(field long_warn)"
printf 'Code, paths and tables do not count. The bar is a ten-year-old reading it once — see signal:plain-english.\n'
printf 'Say the answer once, in your last message. Anything you write before a tool call is already read, so keep it to progress.\n'
printf 'Lead with what is true. If you need the human, ask one bounded thing and name the reply that settles it — see signal:conclusion.
'

[ -n "$last" ] && printf 'Your last reply came in at %s. Cut harder this time.\n' "$last"

exit 0
