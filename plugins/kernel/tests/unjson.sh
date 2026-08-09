#!/bin/bash
# The payload reader: does it find the right value, and does it refuse the wrong one.
#
# Set READER to point these checks at a deliberately broken copy.

set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
. "$here/tests/lib.sh"

reader="${READER:-$here/hooks/lib/unjson.awk}"

# Read a path out of a payload.
read_path() { printf '%s' "$2" | awk -f "$reader" -v path="$1" 2>/dev/null; }

# Get the reader's exit status for a payload.
status() { printf '%s' "$2" | awk -f "$reader" -v path="$1" >/dev/null 2>&1; echo $?; }

# Determine if this system can bound a runaway. macOS ships no `timeout`; Linux and Git Bash do.
have_timeout() { command -v timeout >/dev/null 2>&1; }

# Get the reader's exit status, giving up rather than hanging. 124 means it never finished.
bounded() { printf '%s' "$2" | timeout 5 awk -f "$reader" -v path="$1" >/dev/null 2>&1; echo $?; }

echo "unjson"

# --- the shapes a hook actually receives ---

is "a nested value" \
   "$(read_path tool_input.file_path '{"tool_input":{"file_path":"/a/b.php"}}')" "/a/b.php"

is "a nested value after its siblings" \
   "$(read_path tool_input.file_path '{"session_id":"s1","tool_name":"Write","tool_input":{"file_path":"/x/y.ts","content":"hi"}}')" "/x/y.ts"

is "a top-level value" \
   "$(read_path session_id '{"session_id":"abc123","tool_input":{}}')" "abc123"

is "the alternate path key" \
   "$(read_path tool_input.pathInProject '{"tool_input":{"pathInProject":"src/A.php"}}')" "src/A.php"

is "a pretty-printed payload" \
   "$(read_path tool_input.file_path '{
  "tool_input": {
    "file_path": "/multi/line.php"
  }
}')" "/multi/line.php"

is "an escaped slash and quote" \
   "$(read_path tool_input.file_path '{"tool_input":{"file_path":"/a\/b \"q\".php"}}')" '/a/b "q".php'

# --- the key that is really a value ---
#
# This is why the reader walks instead of searching. A PostToolUse payload carries the content being
# written, and writing a JSON fixture puts the very key we are looking for inside a string. Anything
# that greps for `"file_path"` reads the decoy and hands the ADR nudge the wrong verdict.

is "content holding the same key does not win" \
   "$(read_path tool_input.file_path '{"tool_input":{"file_path":"/real.json","content":"{\"file_path\": \"/decoy.php\"}"}}')" "/real.json"

is "a key one level too deep is not the key" \
   "$(read_path file_path '{"tool_input":{"file_path":"/nested.php"}}')" ""

is "an array is stepped over whole" \
   "$(read_path tool_input.file_path '{"edits":[{"file_path":"/nope.php"}],"tool_input":{"file_path":"/yes.php"}}')" "/yes.php"

# --- saying no ---

is "a missing path exits 1" "$(status tool_input.file_path '{"tool_input":{"content":"x"}}')" "1"
is "a present path exits 0" "$(status tool_input.file_path '{"tool_input":{"file_path":"/a"}}')" "0"
is "an empty value is still a value" "$(status tool_input.file_path '{"tool_input":{"file_path":""}}')" "0"
is "junk that is not JSON exits 1" "$(status tool_input.file_path 'not json at all')" "1"
is "an empty payload exits 1" "$(status tool_input.file_path '')" "1"
is "a truncated payload exits 1" "$(status b '{"a":1')" "1"

# --- and it always finishes ---
#
# Every branch of the walk has to move the cursor. A stray `]` is its own terminator, so the scan
# for a bare token stops where it started, and without a guard the reader rereads that character
# until the hook's timeout kills it. A malformed payload should cost an exit code, not a turn.

if have_timeout; then
  for junk in '{"a":]}' '{"a":}' '{]' '{"a":[1,2}' '{{{{' '}}}}'; do
    rc=$(bounded a "$junk")
    [ "$rc" = "124" ] && bad "malformed payload hung the reader — $junk" \
                      || ok "malformed payload terminates — $junk"
  done
else
  skip "malformed payloads — no timeout here, so a hang could not be told from a pass"
fi

summary "unjson"
