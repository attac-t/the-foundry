#!/bin/bash
# Plants each fault `bin/hookfiles.sh` exists for in a copy, and reads its exit code and its words.
#
# A copy holds the gate, its reader, and every plugin's real `hooks.json`. Each case changes one of
# them, so a pass proves the gate saw that change and nothing else. #1074.

root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="${TMPDIR:-/tmp}/hookfiles-$$"
trap 'rm -rf "$tmp"' EXIT
passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

# A fresh copy: the gate, the reader, and each plugin's shipped hooks.json.
a_lab() {
  local shipped name
  rm -rf "$tmp/lab" && mkdir -p "$tmp/lab/bin" || return 1
  cp "$root/bin/hookfiles.sh" "$root/bin/hookfiles.awk" "$tmp/lab/bin/" || return 1
  for shipped in "$root"/plugins/*/hooks/hooks.json; do
    name=${shipped%/hooks/hooks.json}; name=${name##*/}
    mkdir -p "$tmp/lab/plugins/$name/hooks" && cp "$shipped" "$tmp/lab/plugins/$name/hooks/" || return 1
  done
}

# Run the copy's gate, and say its exit code and what it printed.
gate() { said=$(sh "$tmp/lab/bin/hookfiles.sh" 2>&1); code=$?; }

expect() { # <name> <exit> [<words the gate must say>]
  [ "$code" -eq "$2" ] || { bad "$1 — exited $code, not $2"; return; }
  [ -z "${3:-}" ] || printf '%s\n' "$said" | grep -qF -- "$3" || { bad "$1 — never said [$3]"; return; }
  ok "$1"
}

plugins() { for file in "$root"/plugins/*/hooks/hooks.json; do p=${file%/hooks/hooks.json}; printf '%s\n' "${p##*/}"; done; }

minified_with_a_second_key() { tr -d ' \t\r\n' < "$1" | sed 's/}$/,"outputStyle":"x"}/'; }
indented_by_four_with_a_second_key() { sed 's/^/  /' "$1" | sed '$s/}[[:space:]]*$/, "outputStyle": "x" }/'; }

# --- the shipped files ---

a_lab || { bad "no lab could be made"; exit 1; }
gate
expect "every shipped hooks.json passes" 0 "PASS"

# --- a second key, in each plugin's file, in two layouts the old sed could not see ---

for plugin in $(plugins); do
  file="$tmp/lab/plugins/$plugin/hooks/hooks.json"

  a_lab && minified_with_a_second_key "$root/plugins/$plugin/hooks/hooks.json" > "$file.new" && mv "$file.new" "$file"
  gate
  expect "$plugin's file, minified, with a second key" 1 "plugins/$plugin/hooks/hooks.json holds a key Claude Code drops: \"outputStyle\""

  a_lab && indented_by_four_with_a_second_key "$root/plugins/$plugin/hooks/hooks.json" > "$file.new" && mv "$file.new" "$file"
  gate
  expect "$plugin's file, indented by four, with a second key" 1 "plugins/$plugin/hooks/hooks.json holds a key Claude Code drops: \"outputStyle\""
done

# --- what must never be read as a top-level key, one case each ---

one=$(plugins | head -1)

a_lab && printf '{"hooks": {"Stop": [{"inner": "x"}]}}\n' > "$tmp/lab/plugins/$one/hooks/hooks.json"
gate
expect "a key nested under hooks is never read as top-level" 0 "PASS"

a_lab && printf '{"hooks": {"Stop": [{"command": "says \\"outputStyle\\": here"}]}}\n' > "$tmp/lab/plugins/$one/hooks/hooks.json"
gate
expect "key-like text inside a string is never read as a key" 0 "PASS"

a_lab && printf '{"description": "what these hooks do", "hooks": {}}\n' > "$tmp/lab/plugins/$one/hooks/hooks.json"
gate
expect "a description beside hooks passes" 0 "PASS"

# A key with an empty name is still a key. Read bare, it was a blank line, and a blank line passed.
a_lab && printf '{"": "x", "hooks": {}}\n' > "$tmp/lab/plugins/$one/hooks/hooks.json"
gate
expect "a key with an empty name fails" 1 "holds a key Claude Code drops: \"\""

# --- an empty read is never a clean one ---

a_lab && printf '{"description": "nothing else"}\n' > "$tmp/lab/plugins/$one/hooks/hooks.json"
gate
expect "a file with no hooks key fails" 1 "plugins/$one/hooks/hooks.json holds no hooks key"

a_lab && printf '[{"hooks": {}}]\n' > "$tmp/lab/plugins/$one/hooks/hooks.json"
gate
expect "a top-level array fails, since it holds no hooks key" 1 "holds no hooks key"

a_lab && rm -rf "$tmp/lab/plugins"
gate
expect "a glob that finds no file exits 3" 3 "nothing was read"

printf 'hookfiles — %d passed, %d failed\n' "$passed" "$failed"
[ "$((passed + failed))" -gt 0 ] || { printf 'FAIL — the suite ran nothing.\n'; exit 1; }
[ "$failed" -eq 0 ]
