#!/bin/bash
# Proves the hook can read the agent's text out of the hook JSON without jq.
#
# The case that matters: agents write about code, so a reply can hold the words
# "stop_hook_active": true as plain text. A reader that grabs the first key it sees would read
# the agent's prose as the flag and stand down when it should block. These tests aim straight at that.

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
. "$root/tests/lib.sh"

reader="$root/lib/unjson.awk"
tmp="${TMPDIR:-/tmp}/signal-unjson-$$"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT

#
# Read a key out of a JSON fixture.
#
value() { awk -f "$reader" -v key="$2" < "$1"; }

#
# Read a key and get the exit code instead of the value.
#
status() { awk -f "$reader" -v key="$2" < "$1" >/dev/null 2>&1; echo $?; }

echo "unjson"

# --- the trap: the flag's name appears inside the message, before the real flag ---
cat > "$tmp/trap.json" <<'JSON'
{
  "session_id": "abc",
  "last_assistant_message": "The docs show \"stop_hook_active\": true in the input.",
  "stop_hook_active": false,
  "hook_event_name": "Stop"
}
JSON
is "the real flag wins over the same name in prose" "$(value "$tmp/trap.json" stop_hook_active)" "false"

cat > "$tmp/trap2.json" <<'JSON'
{
  "stop_hook_active": true,
  "last_assistant_message": "Here \"stop_hook_active\": false is only prose."
}
JSON
is "flag read correctly when it comes first" "$(value "$tmp/trap2.json" stop_hook_active)" "true"

# --- nesting must not leak ---
cat > "$tmp/nested.json" <<'JSON'
{
  "effort": { "level": "medium", "last_assistant_message": "decoy" },
  "background_tasks": [ { "id": "1", "type": "shell" } ],
  "last_assistant_message": "real one",
  "session_crons": []
}
JSON
is "nested keys are skipped"      "$(value "$tmp/nested.json" last_assistant_message)" "real one"
is "a nested-only key is absent"  "$(status "$tmp/nested.json" level)"                  1
is "a missing key exits 1"        "$(status "$tmp/nested.json" nope)"                   1

# --- escapes ---
cat > "$tmp/esc.json" <<'JSON'
{"a":"one\ntwo","b":"tab\there","c":"quote \" here","d":"slash \\ here"}
JSON
is "newline escape becomes a newline" "$(value "$tmp/esc.json" a)" "$(printf 'one\ntwo')"
is "tab escape becomes a tab"         "$(value "$tmp/esc.json" b)" "$(printf 'tab\there')"
is "quote escape becomes a quote"     "$(value "$tmp/esc.json" c)" 'quote " here'
is "backslash escape survives"        "$(value "$tmp/esc.json" d)" 'slash \ here'

# A six-byte escape, built from a variable holding one backslash. Typed inline, an editor
# normalises it to a real dash and the test silently checks nothing.
slash='\'
printf '%s' "{\"e\":\"dash ${slash}u2014 here\"}" > "$tmp/uni.json"
is "the fixture really holds an escape" "$(cut -c1-20 "$tmp/uni.json")" "{\"e\":\"dash ${slash}u2014 he"
is "a unicode escape becomes a space"   "$(value "$tmp/uni.json" e)" 'dash   here'

# --- a real message, fences and all ---
cat > "$tmp/fence.json" <<'JSON'
{"last_assistant_message":"Run it.\n\n```bash\necho \"hi\"\n```\n","stop_hook_active":false}
JSON
reply=$(value "$tmp/fence.json" last_assistant_message)
has "a fenced block survives the read" "$reply" '```bash'
has "quotes inside the fence survive"  "$reply" 'echo "hi"'

# --- shape does not matter ---
printf '{"stop_hook_active":false,"last_assistant_message":"flat"}' > "$tmp/flat.json"
is "single-line JSON works" "$(value "$tmp/flat.json" last_assistant_message)" "flat"

printf '{\n  "last_assistant_message"  :  "spaced"  ,\n  "x": 1\n}\n' > "$tmp/spaced.json"
is "odd spacing works"      "$(value "$tmp/spaced.json" last_assistant_message)" "spaced"

printf '{"last_assistant_message":"","stop_hook_active":false}' > "$tmp/empty.json"
is "an empty message reads as empty" "$(value "$tmp/empty.json" last_assistant_message)" ""
is "an empty message still exits 0"  "$(status "$tmp/empty.json" last_assistant_message)" 0

summary "unjson"
