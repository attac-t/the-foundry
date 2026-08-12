#!/bin/bash
# Drives the hook the way Claude Code drives it: JSON on stdin, JSON back.
#
# The loop guard is the test that matters. A Stop hook that always blocks never lets a turn end.
# It keys on a per-prompt marker, not on `stop_hook_active` alone: that flag is set by any Stop
# hook, so another plugin's block used to silence this one.
#
# The second thing checked here is what a middling reply costs. Anything over the working line but
# under the tail must leave a note and print nothing, because printing costs the reader a second
# reply for a first one they had already read.

#
# Set PLUGIN_ROOT to point these checks at a deliberately broken copy.

set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
root="${PLUGIN_ROOT:-$here}"
. "$here/tests/lib.sh"

hook="$root/hooks/signal.sh"
sanitiser="$root/lib/jsonsafe.awk"
session="signal-test-$$"
mark="${TMPDIR:-/tmp}/signal-${session}.mark"
note="${TMPDIR:-/tmp}/signal-${session}.note"
trap 'rm -f "$mark" "$note"' EXIT

# Long enough to clear the tail: 600 words, a 45-word sentence, or a quarter of them long.
bad='Additionally, it is worth noting that we should leverage this comprehensive functionality in order to facilitate a robust implementation, and furthermore the extraordinarily sophisticated architectural considerations demonstrate fundamentally comprehensive capabilities.'
good='We cut it by ten. The hook reads what the agent said.'
near='The elephant sat on a mat. My family went to the shop and got some milk today.'

# Over the working line, under the tail. The note gets the numbers and the reader gets nothing.
middling='The elephant sat on a mat and the family went to the shop to get some milk today, which took a while because the shop was shut and they had to walk on to the next one.'

# Build hook input from a flag, a reply, and a prompt id. Replies here carry no quotes.
payload() {
  printf '{"session_id":"%s","prompt_id":"%s","stop_hook_active":%s,"last_assistant_message":"%s","hook_event_name":"Stop"}' \
    "$session" "${3:-p1}" "$1" "$2"
}

# Run the hook and get what it printed.
run() { printf '%s' "$1" | bash "$hook" 2>/dev/null; }

# Run the hook and get its exit code.
status() { printf '%s' "$1" | bash "$hook" >/dev/null 2>&1; echo $?; }

# Remove the marker.
forget() { rm -f "$mark"; }

# Write a prompt id into the marker.
claim() { printf '%s' "$1" > "$mark"; }

# Remove the note.
unnote() { rm -f "$note"; }

# Read what the note holds, if anything.
noted() { cat "$note" 2>/dev/null; }

# Count how far the braces fail to balance.
braces() { printf '%s' "$1" | awk '{ print gsub(/{/, "{") - gsub(/}/, "}") }'; }

# Determine whether the quotes come in pairs. Zero means they do.
quotes() { printf '%s' "$1" | awk '{ print gsub(/"/, "\"") % 2 }'; }

echo "guard"

# --- the loop guard ---

forget
out=$(run "$(payload false "$bad" p1)")
has "the first stop blocks" "$out" '"decision":"block"'

out=$(run "$(payload true "$bad" p1)")
has   "a rewrite still over budget tells you" "$out" '"systemMessage"'
lacks "the second stop does not block"        "$out" '"decision"'

out=$(run "$(payload true "$good" p1)")
is "a rewrite that fixed it is silent" "$out" ""

# Another plugin blocked, so the flag is set but no marker names this prompt. We still owe a score.
forget
out=$(run "$(payload true "$bad" p1)")
has "another plugin's block does not silence us" "$out" '"decision":"block"'

claim p-earlier
out=$(run "$(payload true "$bad" p1)")
has "a marker from an earlier turn does not silence us" "$out" '"decision":"block"'

# No prompt id to key on. We cannot tell our own block from anyone else's, so warn, never block.
forget
out=$(printf '{"session_id":"%s","stop_hook_active":true,"last_assistant_message":"%s"}' "$session" "$bad" | bash "$hook" 2>/dev/null)
lacks "with no prompt id we never block" "$out" '"decision"'

claim p1
printf '%s' 'stale' > "$note"
printf '{"session_id":"%s","hook_event_name":"SessionEnd"}' "$session" | bash "$root/hooks/cleanup.sh" >/dev/null 2>&1
[ -f "$mark" ] && bad "SessionEnd left the marker behind" || ok "SessionEnd drops the marker"
[ -f "$note" ] && bad "SessionEnd left the note behind"   || ok "SessionEnd drops the note"
forget
unnote

# --- the three answers ---
#
# Only two of them reach anybody now. A reply over the working line but under the tail leaves its
# numbers in the note and prints nothing: `systemMessage` reaches the reader and never the agent, so
# printing them told the one party who cannot act on them, beside a reply they had already read.

is "clean text says nothing" "$(run "$(payload false "$good")")" ""

unnote
out=$(run "$(payload false "$middling")")
is    "an ordinary overshoot says nothing to the reader" "$out" ""
has   "an ordinary overshoot leaves its numbers in the note" "$(noted)" 'longest sentence 37'

unnote
out=$(run "$(payload false "$near")")
is "a near miss says nothing to the reader either" "$out" ""
has "a near miss still leaves a note" "$(noted)" 'long words'

# A reply inside the budget has nothing to answer for, so last turn's numbers must not follow it.
printf '%s' 'stale numbers from an earlier turn' > "$note"
run "$(payload false "$good")" >/dev/null
is "clean text drops the note" "$(noted)" ""

# --- the block message has to be usable ---

unnote
out=$(run "$(payload false "$bad")")
has "the block names the numbers"   "$out" 'long words'
has "the block gives the target"    "$out" 'aim for'
has "the block points at the skill" "$out" 'signal:plain-english'
has "the block says the long one is already read" "$out" 'already read'
has "a block leaves a note too"     "$(noted)" 'long words'

# The sanitiser keeps letters, digits, space and `.,:%-`, so anything else we write is dropped where
# it stood and its spaces are not. A double space is what a stripped character looks like from here,
# and an em dash in the advice is how this was found.
lacks "nothing signal prints loses a character to the sanitiser" "$out" '  '

forget
unnote

# --- nothing to score ---

is "no reply means no output"    "$(run '{"session_id":"t","stop_hook_active":false}')" ""
is "an empty reply says nothing" "$(run "$(payload false "")")" ""

# --- a hook must never fail ---
# A non-zero exit is reported to the user as a hook error, whatever the verdict was.

codes=""
for pair in "false|$good" "false|$near" "false|$bad" "true|$bad" "false|"; do
  codes="$codes$(status "$(payload "${pair%%|*}" "${pair#*|}")")"
done
is "the hook never exits non-zero" "$codes" "00000"

# --- the output must be JSON ---

out=$(run "$(payload false "$bad")")
is "output is one line"   "$(printf '%s' "$out" | wc -l | tr -d ' ')" 0
is "braces balance"       "$(braces "$out")" 0
is "quotes come in pairs" "$(quotes "$out")" 0

# A reply full of quotes must not break the JSON. Nothing from the agent's text reaches the strings we
# print, so this should hold by design — and "by design" is how the vacuous checks got written.
quoted='He said \"leverage it\" and then \"facilitate that\" and \"utilise this\" comprehensively.'
out=$(run "$(payload false "$quoted")")
has "a quoted reply still blocks"     "$out" '"decision":"block"'

# --- the sanitiser ---
# Tested through the shipped file. An earlier version inlined a copy of the expression, so
# replacing the real one with `cat` left every check green.

is "the sanitiser drops quotes"      "$(printf 'a"b"c' | awk -f "$sanitiser")" 'abc'
is "the sanitiser drops backslashes" "$(printf 'a\\b' | awk -f "$sanitiser")" 'ab'
is "the sanitiser drops controls"    "$(printf 'a\001b\002c' | awk -f "$sanitiser")" 'abc'
is "the sanitiser folds newlines"    "$(printf 'one\ntwo' | awk -f "$sanitiser")" 'one two'
is "the sanitiser keeps the numbers" "$(printf '32%% long, 40 words: aim-for 20.' | awk -f "$sanitiser")" '32% long, 40 words: aim-for 20.'

# --- the dials reach the scorer ---

out=$(SIGNAL_WORDS_BLOCK=1 SIGNAL_WORDS_WARN=1 run "$(payload false "$good")")
has "a tighter word budget blocks clean text" "$out" '"decision":"block"'

summary "guard"
