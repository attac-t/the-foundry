#!/bin/sh
#
# Stop: hold the agent's last reply to a budget a ten-year-old can skim.
#
# Blocking cannot unsend what the reader already read. It only sets a second reply beside the first,
# which is worth a turn when the first cannot be skimmed at all, and never otherwise. Below that
# line we correct forward: warn leaves the numbers in a note and hooks/brief.sh reads them out
# before the agent writes again.
#
# Pass drops the note. Warn writes it. Block writes it and hands the reply back, once.
# All the judging lives in lib/score.awk.
#
# No `set -e`: the scorer answers in its exit status, and the assignment that reads it would take a
# warn for a failure and kill the hook mid-turn.
#

root="$(cd "$(dirname "$0")/.." && pwd)"
temp="${TMPDIR:-/tmp}"
payload=$(cat)

# Read a value from the hook payload.
value() { printf '%s' "$payload" | awk -f "$root/lib/unjson.awk" -v key="$1"; }

# Determine if the turn is already running on because of a stop hook.
continuing() { [ "$(value stop_hook_active)" = "true" ]; }

# Get the path to this session's marker.
markfile() { printf '%s/signal-%s.mark' "$temp" "${session:-nosession}"; }

# Determine if the marker names the prompt in flight.
ours() { [ "$(cat "$(markfile)" 2>/dev/null)" = "$prompt" ]; }

# Determine if the temp directory can hold a marker.
keepable() { [ -w "$temp" ]; }

# Record that we blocked this prompt, and answer whether it
# stuck. A block we cannot remember is one we take
# again next turn, and every turn after it.
remember() { printf '%s' "$prompt" > "$(markfile)" 2>/dev/null; }

# Get the path to this session's note.
notefile() { printf '%s/signal-%s.note' "$temp" "${session:-nosession}"; }

# Leave the numbers where the next turn's brief will find them.
note() { printf '%s' "$1" > "$(notefile)" 2>/dev/null; }

# Drop them. A reply inside the budget has nothing to answer for.
forget() { rm -f "$(notefile)" 2>/dev/null; }

# Score a reply and return its report. Unset dials pass through empty: score.awk owns the defaults,
# and a hook that names them again is half a gate, free to drift from the other half.
score() {
  printf '%s' "$1" | awk -f "$root/lib/score.awk" \
    -v long_warn="${SIGNAL_LONG_WARN:-}"    -v long_block="${SIGNAL_LONG_BLOCK:-}" \
    -v sent_warn="${SIGNAL_SENT_WARN:-}"    -v sent_block="${SIGNAL_SENT_BLOCK:-}" \
    -v words_warn="${SIGNAL_WORDS_WARN:-}"  -v words_block="${SIGNAL_WORDS_BLOCK:-}"
}

# Get a single field from the report.
field() { printf '%s\n' "$report" | awk -F= -v k="$1" '$1 == k { sub(/^[^=]*=/, ""); print; exit }'; }

# Reduce a string to characters that cannot break a JSON literal.
safe() { printf '%s' "$1" | awk -f "$root/lib/jsonsafe.awk"; }

# Tell the reader, and let the turn end. Kept for the one case we owe them: a rewrite we asked for
# that came back still over. `systemMessage` never reaches the agent, so ordinary overshoot would be
# handing the numbers to the only party who cannot act on them. That goes to the note.
warn() { printf '{"systemMessage":"signal: %s"}\n' "$(safe "$1")"; }

# Hand the reply back to the agent to write again, and tell the reader it went back.
#
# Two audiences, one object. `reason` reaches the agent and `systemMessage` reaches the reader, which
# is why `warn` above needs the second one — and why blocking without it leaves a reader holding two
# replies with nothing saying which was sent.
block() {
    printf '{"decision":"block","reason":"%s","systemMessage":"%s"}\n' \
        "$(safe "$1")" "signal: that reply went back to be said again. The next one is the answer."
}

# Get the rewrite instructions. ASCII only: jsonsafe.awk drops an em dash and leaves its two spaces.
advice() { printf '%s' "They have already read the long one, so do not write it again. Answer first, in one line, and drop the route you took. Keep every fact. Cut the words. For every word, ask whether a ten-year-old would use it, and whether a plainer word means the same. Read the signal:plain-english skill, which names the standard."; }

#
# Determine if we have already spent our one block on this prompt.
#
# `stop_hook_active` says some stop hook caused the continuation, not which one. Any other plugin can
# hook Stop, so we track our own block. When we cannot tell, assume we blocked: standing down too
# readily beats blocking every turn.
#
spent() {
  continuing       || return 1
  [ -n "$prompt" ] || return 0
  ours             && return 0
  keepable         || return 0
  return 1
}

# Both ids land in a file path, so keep them to characters that cannot climb out of one.
session=$(value session_id | tr -cd 'A-Za-z0-9._-')
prompt=$(value prompt_id  | tr -cd 'A-Za-z0-9._-')

# No message on the event, or none we could read. Falling through would score nothing, call it a
# pass, and drop the note the last real reply earned.
reply=$(value last_assistant_message)
[ -n "$reply" ] || exit 0

report=$(score "$reply")
verdict=$?
[ "$verdict" -eq 0 ] && { forget; exit 0; }

why=$(field reason)
note "$why"

spent && { warn "rewrite still over: $why. One block per turn, so this one ships."; exit 0; }

# Over the working line, under the tail. The note has it. Anything more costs a second reply.
[ "$verdict" -eq 1 ] && exit 0

remember || { warn "over the line, and this block could not be tracked: $why"; exit 0; }

block "Say that again in plain English. $why. $(advice)"
exit 0
