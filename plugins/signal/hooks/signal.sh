#!/bin/sh
#
# Stop: hold the agent's last reply to a budget a ten-year-old can skim.
#
# Blocking cannot unsend what the reader already read. `Stop` fires after the reply is finished and
# on screen, so handing it back never takes it away — it only puts a second reply beside the first.
# That is worth a turn only when the first one cannot be skimmed at all.
#
# Everything under that line is corrected forward instead. Warn writes the numbers to a note, says
# nothing to anyone now, and hooks/brief.sh reads them out before the agent writes again. Feedback
# at no turns and no second reply.
#
# Pass drops the note. Warn writes it. Block writes it and hands the reply back, once.
# All the judging lives in lib/score.awk.
#

root="$(cd "$(dirname "$0")/.." && pwd)"
temp="${TMPDIR:-/tmp}"
payload=$(cat)

# Read a value from the hook payload.
value() { printf '%s' "$payload" | awk -f "$root/lib/unjson.awk" -v key="$1"; }

# Determine if the turn is already running on because of a stop hook.
continuing() { [ "$(value stop_hook_active)" = "true" ]; }

# Get the path to this session's marker file.
marker() { printf '%s/signal-%s.mark' "$temp" "${session:-nosession}"; }

# Determine if the marker names the prompt in flight.
ours() { [ "$(cat "$(marker)" 2>/dev/null)" = "$prompt" ]; }

# Determine if the temp directory can hold a marker.
keepable() { [ -w "$temp" ]; }

# Record that we blocked this prompt.
remember() { printf '%s' "$prompt" > "$(marker)" 2>/dev/null; }

# Get the path to this session's note.
notefile() { printf '%s/signal-%s.note' "$temp" "${session:-nosession}"; }

# Leave the numbers where the next turn's brief will find them.
note() { printf '%s' "$1" > "$(notefile)" 2>/dev/null; }

# Drop them. A reply inside the budget has nothing to answer for.
forget() { rm -f "$(notefile)" 2>/dev/null; }

#
# Score a reply and return its report.
#
# Every dial is passed through empty when it is unset, because score.awk owns the defaults. Naming
# them here as well is how the two halves came apart: the block lines moved in the scorer and this
# line went on handing it the old ones, so the shipped gate was whatever the hook said it was.
#
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

#
# Tell the reader, and let the turn end.
#
# Kept for one case only: a rewrite we asked for that came back still over. The reader is about to
# read a long reply for the second time and signal owes them the admission.
#
# Ordinary overshoot says nothing here. `systemMessage` reaches the reader and never the agent, so
# printing the numbers told the one party who cannot act on them, in front of the reply they are
# already looking at. The note carries them to the party who can.
#
warn() { printf '{"systemMessage":"signal: %s"}\n' "$(safe "$1")"; }

# Hand the reply back to the agent to write again.
block() { printf '{"decision":"block","reason":"%s"}\n' "$(safe "$1")"; }

#
# Get the rewrite instructions.
#
# ASCII only, and that is not a style choice. Everything here goes through jsonsafe.awk, which keeps
# letters, digits, space and `.,:%-` and drops the rest. An em dash leaves its two spaces behind and
# the agent reads a gap where the punctuation was.
#
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

reply=$(value last_assistant_message)
[ -n "$reply" ] || exit 0

report=$(score "$reply")
verdict=$?
[ "$verdict" -eq 0 ] && { forget; exit 0; }

why=$(field reason)
note "$why"

spent && { warn "rewrite still over: $why. One block per turn, so this one ships."; exit 0; }

# Over the working line, under the tail. The note already has the numbers and the next turn will
# read them out, so there is nothing left to do here that would not cost the reader a second reply.
[ "$verdict" -eq 1 ] && exit 0

remember
block "Say that again in plain English. $why. $(advice)"
exit 0
