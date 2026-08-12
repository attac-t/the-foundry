#!/bin/bash
# Drives the UserPromptSubmit hook the way Claude Code drives it: JSON on stdin, plain text back.
#
# Plain text is the point. On this event stdout is handed to the agent, so the budget arrives before
# the reply exists — the only moment anything can stop a long one reaching the reader. Everywhere
# else signal speaks JSON, and JSON here would be read as a literal instead of an instruction.
#
# The other half is the handoff. Stop leaves the last reply's numbers in a note and this reads them
# out, so the correction lands on the next reply instead of costing the reader a second one.

#
# Set PLUGIN_ROOT to point these checks at a deliberately broken copy.

set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
root="${PLUGIN_ROOT:-$here}"
. "$here/tests/lib.sh"

hook="$root/hooks/brief.sh"
session="signal-brief-$$"
note="${TMPDIR:-/tmp}/signal-${session}.note"
trap 'rm -f "$note"' EXIT

# Build hook input.
payload() { printf '{"session_id":"%s","hook_event_name":"UserPromptSubmit","prompt":"%s"}' "$session" "${1:-go}"; }

# Run the hook and get what it printed.
run() { printf '%s' "$(payload)" | bash "$hook" 2>/dev/null; }

# Run the hook and get its exit code.
status() { printf '%s' "$(payload)" | bash "$hook" >/dev/null 2>&1; echo $?; }

# Leave numbers behind the way signal.sh does.
leave() { printf '%s' "$1" > "$note"; }

echo "brief"

# --- the budget arrives before the reply ---

out=$(run)
has "the brief states the word budget"     "$out" '120 words'
has "the brief states the sentence budget" "$out" 'no sentence over 20'
has "the brief states the long-word share" "$out" 'long words under 10%'
has "the brief names the bar"              "$out" 'ten-year-old'
has "the brief points at the skill"        "$out" 'signal:plain-english'
has "the brief says what does not count"   "$out" 'Code, paths and tables'

# The agent reads this, so it must not arrive wrapped in JSON it would quote back.
lacks "the brief is plain text, not JSON" "$out" '{"'

# --- the brief quotes the gate, never a copy of it ---
# Read out of the scorer here too, so a budget that moves in one place moves in both or this fails.

gate() { printf '' | awk -f "$root/lib/score.awk" | awk -F= -v k="$1" '$1 == k { print $2; exit }'; }

has "the brief quotes the scorer's word budget"     "$out" "$(gate words_warn) words"
has "the brief quotes the scorer's sentence budget" "$out" "over $(gate sent_warn)"
has "the brief quotes the scorer's long-word share" "$out" "under $(gate long_warn)%"

# --- the dials reach the brief ---
# A project that loosens the budget must be told its own numbers, not the ones we ship.

out=$(printf '%s' "$(payload)" | SIGNAL_WORDS_WARN=400 SIGNAL_SENT_WARN=35 SIGNAL_LONG_WARN=18 bash "$hook" 2>/dev/null)
has "a tuned word budget reaches the brief"     "$out" '400 words'
has "a tuned sentence budget reaches the brief" "$out" 'no sentence over 35'
has "a tuned long-word share reaches the brief" "$out" 'long words under 18%'

# --- the handoff from Stop ---

rm -f "$note"
lacks "with no note the brief says nothing about the last reply" "$(run)" 'last reply'

leave '327 words, aim for 120'
out=$(run)
has "a note reaches the agent"       "$out" '327 words, aim for 120'
has "and it asks for the cut"        "$out" 'Cut harder'

# One turn, one answer. A note that outlived its turn would nag about a reply already rewritten.
[ -f "$note" ] && bad "the brief left the note behind" || ok "the brief drops the note once read"

leave 'longest sentence 47 words, aim for 20'
run >/dev/null
lacks "a note is never read twice" "$(run)" 'longest sentence 47'

# --- a hook must never fail ---
# A non-zero exit on this event is reported to the user as a hook error, every prompt they type.

rm -f "$note"
is "the hook exits zero with no note" "$(status)" 0
leave 'anything'
is "the hook exits zero with a note"  "$(status)" 0

is "an empty payload still exits zero" "$(printf '{}' | bash "$hook" >/dev/null 2>&1; echo $?)" 0
has "and still states the budget"      "$(printf '{}' | bash "$hook" 2>/dev/null)" '120 words'

# --- the brief holds itself to the budget it preaches ---
# It lands in context on every prompt. A brief that broke its own gate would be the plugin's
# loudest counter-example, and it would spend the budget it is asking the agent to keep.

rm -f "$note"
run | awk -f "$root/lib/score.awk" >/dev/null 2>&1
is "the brief clears its own gate" "$?" 0

summary "brief"
