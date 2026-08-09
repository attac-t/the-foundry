#!/bin/bash
#
# Stop: hold the agent's last reply to a budget a ten-year-old can skim.
#
# Pass says nothing. Warn reaches the user and costs no turn. Block reaches the agent and costs one.
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

# Score a reply and return its report.
score() {
  printf '%s' "$1" | awk -f "$root/lib/score.awk" \
    -v long_warn="${SIGNAL_LONG_WARN:-10}"    -v long_block="${SIGNAL_LONG_BLOCK:-15}" \
    -v sent_warn="${SIGNAL_SENT_WARN:-20}"    -v sent_block="${SIGNAL_SENT_BLOCK:-30}" \
    -v words_warn="${SIGNAL_WORDS_WARN:-120}" -v words_block="${SIGNAL_WORDS_BLOCK:-250}"
}

# Get a single field from the report.
field() { printf '%s\n' "$report" | awk -F= -v k="$1" '$1 == k { sub(/^[^=]*=/, ""); print; exit }'; }

# Reduce a string to characters that cannot break a JSON literal.
safe() { printf '%s' "$1" | awk -f "$root/lib/jsonsafe.awk"; }

# Tell the user, and let the turn end.
warn() { printf '{"systemMessage":"signal: %s"}\n' "$(safe "$1")"; }

# Hand the reply back to the agent to write again.
block() { printf '{"decision":"block","reason":"%s"}\n' "$(safe "$1")"; }

# Get the rewrite instructions.
advice() { printf '%s' "Keep every fact. Cut the words. For every word, ask whether a ten-year-old would use it, and whether a plainer word means the same. Read the signal:plain-english skill, which names the standard."; }

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
[ "$verdict" -eq 0 ] && exit 0

why=$(field reason)

spent && { warn "rewrite still over — $why. One block per turn, so this one ships."; exit 0; }

[ "$verdict" -eq 1 ] && { warn "$why"; exit 0; }

remember
block "Say that again in plain English. $why. $(advice)"
exit 0
