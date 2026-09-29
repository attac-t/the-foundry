#!/bin/bash
# What the shaping entry point makes of what a harness hands back, one row a shape.
#
# Driven through a `claude` this suite writes, so every row is the real script reading a real answer.
# **No network, ever.** A row that needs one goes red on a train.
#
# **Each row names the code floor must read.** So the table fails an entry point that always says 0,
# and one that always says 1: empty output at 0 names 1, and prose at 0 names 0.
#
# A failure printed as text at exit 0 is claude-code #79500's shape, reported in text mode. What JSON
# mode prints then is unmeasured, so both are rows: the text, and an error inside the JSON.

set -u
entry="$(cd "$(dirname "$0")/.." && pwd)/shape.sh"

passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

is() { [ "$2" = "$3" ] && ok "$1" || bad "$1 — want [$3], got [$2]"; }

echo "anthropic shape"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/noclaude" "$tmp/room" "$tmp/alone"

# It keeps its arguments and what its directory held, reads the prompt, and answers as a row wrote.
cat > "$tmp/bin/claude" <<'STUB'
#!/bin/sh
printf '%s\n' "$@" > "$TMP/argv"
ls -A > "$TMP/listing"
cat > "$TMP/prompt"
cat "$TMP/reply"
exit "$(cat "$TMP/code")"
STUB
chmod +x "$tmp/bin/claude"

printf 'run r\nmember m\nattempt 1\n' > "$tmp/brief"

# A harness answering `$2` at exit `$1`.
answering() { printf '%s' "$2" > "$tmp/reply"; printf '%s' "$1" > "$tmp/code"; }

# The entry point run the way floor runs it: in an empty room, handed a brief, stdin closed. What it
# printed lands in `$tmp/printed`, byte for byte, and its code is the answer.
shaped() {
  ( cd "$tmp/room" && PATH="$tmp/bin:$PATH" TMP="$tmp" FOUNDRY_BRIEF="${1-$tmp/brief}" \
      sh "$entry" < /dev/null > "$tmp/printed" 2>/dev/null ); printf '%s' "$?"
}

# One result object, as the harness prints one at the end of a call.
result() { printf '{"type":"result","subtype":"success","is_error":%s,"result":"%s","session_id":"s"}' "$1" "$2"; }

# --- not an answer, so 1 ---

answering 0 'API Error: Request rejected (429), rate limit reached, try again later'
is "a failure the harness prints as text at 0 is 1"       "$(shaped)" "1"

answering 0 '{"type":"result","subtype":"error_during_execution","is_error":true,"result":"API Error: 529"}'
is "an error the harness reports inside its JSON at 0 is 1" "$(shaped)" "1"

answering 0 ''
is "empty output at 0 is 1"                                "$(shaped)" "1"

answering 0 "$(result false '')"
is "an empty result at 0 is 1"                             "$(shaped)" "1"

# --- an answer, so 0, whatever it says ---

answering 0 "$(result false 'I think the page is fine as it stands.')"
is "prose at 0 is 0, since a model answered"               "$(shaped)" "0"
is "and it prints the prose for floor to refuse"          "$(cat "$tmp/printed")" "I think the page is fine as it stands."

answering 0 "$(result false 'nothing')"
is "the line nothing at 0 is 0"                            "$(shaped)" "0"

# Every escape JSON has, and a character outside the basic plane as a surrogate pair.
answering 0 "$(result false 'propose Judged the \"page\" loads\nwhy a\\b\tc\r\nevidence caf\u00e9 \ud83d\ude00 a\/b\bx\fy')"
printf 'propose Judged the "page" loads\nwhy a\\b\tc\r\nevidence caf\303\251 \360\237\230\200 a/b\bx\fy' > "$tmp/wanted"
is "lines in shape at 0 are 0"                             "$(shaped)" "0"
is "and each escape is printed as its bytes" \
   "$(cmp -s "$tmp/printed" "$tmp/wanted" && echo same || od -c "$tmp/printed" | head -3)" "same"

# --- no model answered, so 1 ---

answering 1 "$(result false 'propose Judged it works')"
is "a harness that exits 1 is 1, whatever it printed"      "$(shaped)" "1"

bare="$tmp/noclaude:/usr/bin:/bin"
if PATH="$bare" command -v claude >/dev/null 2>&1; then
  bad "no claude on the path cannot be driven — claude is on the bare PATH"
else
  is "no claude on the path is 1" \
     "$( ( cd "$tmp/room" && PATH="$bare" FOUNDRY_BRIEF="$tmp/brief" sh "$entry" < /dev/null >/dev/null 2>&1 ); printf '%s' "$?")" "1"
fi

# --- floor handed nothing, so 2 ---

is "no brief is 2"                                         "$(shaped "")" "2"
is "and a brief that is not there is 2"                    "$(shaped "$tmp/gone")" "2"

# --- how it asks ---

answering 0 "$(result false 'nothing')"
shaped >/dev/null
is "it asks for one JSON object"  "$(awk 'prev == "--output-format" { print; exit } { prev = $0 }' "$tmp/argv")" "json"
is "with no built-in tool"        "$(awk 'prev == "--tools" { print "[" $0 "]"; exit } { prev = $0 }' "$tmp/argv")" "[]"
is "and no MCP server from a config file" "$(grep -cx -- '--strict-mcp-config' "$tmp/argv")" "1"
is "and no session kept on disk"  "$(grep -cx -- '--no-session-persistence' "$tmp/argv")" "1"
is "in print mode"                "$(sed -n 1p "$tmp/argv")" "-p"
is "and the directory it ran in holds nothing" "$(cat "$tmp/listing")" ""
is "and the brief travels whole, after the frame" "$(tail -n 3 "$tmp/prompt")" "$(cat "$tmp/brief")"

# --- alone ---

cp "$entry" "$tmp/alone/shape.sh"
answering 0 "$(result false 'propose Judged it works\nwhy it matters')"
is "copied alone into an empty directory, it still says 0 on lines in shape" \
   "$( ( cd "$tmp/room" && PATH="$tmp/bin:$PATH" TMP="$tmp" FOUNDRY_BRIEF="$tmp/brief" \
        sh "$tmp/alone/shape.sh" < /dev/null >/dev/null 2>&1 ); printf '%s' "$?")" "0"

printf '\nanthropic shape — %d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
