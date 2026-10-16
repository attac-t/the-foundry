#!/bin/bash
# Plants each fault `bin/routed.sh` exists for in a copy, and reads its exit code and its words.
#
# A copy holds the gate, its reader, floor's runner and floor's README. Each case changes one of
# them, so a pass proves the gate saw that change and nothing else. #1159.

root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="${TMPDIR:-/tmp}/routed-$$"
trap 'rm -rf "$tmp"' EXIT
passed=0
failed=0

ok()  { passed=$((passed + 1)); printf '  ok    %s\n' "$1"; }
bad() { failed=$((failed + 1)); printf '  FAIL  %s\n' "$1"; }

runner=plugins/floor/bin/run.sh
page=plugins/floor/README.md

# A fresh copy: the gate, the reader, the runner and the page.
a_lab() {
  rm -rf "$tmp/lab" && mkdir -p "$tmp/lab/bin" "$tmp/lab/plugins/floor/bin" || return 1
  cp "$root/bin/routed.sh" "$root/bin/routed.awk" "$tmp/lab/bin/" || return 1
  cp "$root/$runner" "$tmp/lab/$runner" && cp "$root/$page" "$tmp/lab/$page"
}

# Run the copy's gate, and say its exit code and what it printed.
gate() { said=$(sh "$tmp/lab/bin/routed.sh" 2>&1); code=$?; }

expect() { # <name> <exit> [<words the gate must say>]
  [ "$code" -eq "$2" ] || { bad "$1 — exited $code, not $2"; return; }
  [ -z "${3:-}" ] || printf '%s\n' "$said" | grep -qF -- "$3" || { bad "$1 — never said [$3]"; return; }
  ok "$1"
}

# One plant, into a fresh copy, then the gate.
planted() { a_lab || { bad "no lab could be made"; return 1; }; ( cd "$tmp/lab" && "$@" ); gate; }

# A green case proves nothing unless its plant is there to be passed over.
landed() { grep -qF -- "$2" "$tmp/lab/$1" || { bad "$3 — the plant never landed"; return 1; }; }

# A function the runner defines, written after everything else.
defined() { printf '%s\n' "$@" >> "$runner"; }

# A call to a function, as the first line of `deliver`.
reached() {
  awk -v call="$1" '{ print } /^deliver\(\) *\{/ { print "    " call }' "$runner" > "$runner.new" \
    && mv "$runner.new" "$runner"
}

# Each line of the page or the runner, filtered through one `sed`.
edited() { sed "$2" "$1" > "$1.new" && mv "$1.new" "$1"; }

# --- the shipped tree ---

planted :
expect "floor as shipped passes" 0 "PASS"

# --- a code nothing routes or names, in each shape an exit takes ---

an_exit_in_a_long_body() { defined 'plant_long() {' '    note "a plant"' '    exit 63' '}'; reached plant_long; }
planted an_exit_in_a_long_body
expect "an exit in a function deliver reaches is named" 1 "63, from \`plant_long\`"

an_exit_in_one_line() { defined 'plant_short() { note "a plant"; exit 64; }'; reached plant_short; }
planted an_exit_in_one_line
expect "and one in a function written on one line" 1 "64, from \`plant_short\`"

an_exit_by_argument() { defined 'plant_passed() { note "a plant"; exit "$2"; }'; reached 'plant_passed a 65'; }
planted an_exit_by_argument
expect "and one passed as an argument, from the call" 1 "65, from \`plant_passed from deliver\`"

an_exit_through_a_value() { defined 'plant_passed() { note "a plant"; exit "$2"; }'; reached 'plant_passed a "$code"'; }
planted an_exit_through_a_value
expect "an argument nothing can read is named, never dropped" 1 "exits through a value nothing could read"

an_exit_through_a_variable() { defined 'plant_held() { kept=7; exit "$kept"; }'; reached plant_held; }
planted an_exit_through_a_variable
expect "an exit through a variable is named, never dropped" 1 "\`plant_held\` exits through a value"

an_exit_through_a_capture() {
  defined 'plant_inner() { return 67; }' 'plant_caught() { said=$(plant_inner) || exit "$?"; }'
  reached plant_caught
}
planted an_exit_through_a_capture
expect "an exit through a capture takes what it captured" 1 "67, from \`plant_caught through plant_inner\`"

#
# One case for each shape an exit takes that no number or argument resolves. Each must be named.
an_exit_with_a_default() { defined 'plant_default() { exit "${2:-1}"; }'; reached plant_default; }
planted an_exit_with_a_default
expect "an exit through a default is named" 1 "\`plant_default\` exits through a value"

an_exit_by_arithmetic() { defined 'plant_sum() { exit $((2 + 2)); }'; reached plant_sum; }
planted an_exit_by_arithmetic
expect "an exit by arithmetic is named" 1 "\`plant_sum\` exits through a value"

a_bare_exit() { defined 'plant_bare() { false || exit; }'; reached plant_bare; }
planted a_bare_exit
expect "a bare exit is named" 1 "\`plant_bare\` exits through a value"

#
# A call after a case arm's `)` is a call, and an exit there is an exit.
a_call_in_a_case_arm() {
  defined 'plant_armed() { note "a plant"; exit 69; }'
  reached 'case "$1" in x) plant_armed ;; esac'
}
planted a_call_in_a_case_arm
expect "a function reached only from a case arm is followed" 1 "69, from \`plant_armed\`"

an_exit_in_a_case_arm() { defined 'plant_arm() { case "$1" in x) exit 70 ;; esac; }'; reached plant_arm; }
planted an_exit_in_a_case_arm
expect "an exit after a case arm is read" 1 "70, from \`plant_arm\`"

an_awk_exit() { defined "plant_awk() { awk '{ exit 71 }' /dev/null; }"; reached plant_awk; }
planted an_awk_exit
landed "$runner" 'exit 71' "an awk program's exit is awk's" \
  && expect "an awk program's exit is awk's" 0 "PASS"

a_page_naming_an_exit() { defined 'plant_page() {' '    cat <<EOF' 'a page; exit 72' 'EOF' '}'; reached plant_page; }
planted a_page_naming_an_exit
landed "$runner" 'a page; exit 72' "a heredoc's page is text" \
  && expect "a heredoc's page is text" 0 "PASS"

an_exit_nobody_reaches() { defined 'plant_far() { note "a plant"; exit 66; }'; }
planted an_exit_nobody_reaches
landed "$runner" 'plant_far()' "a code no call reaches is not deliver's" \
  && expect "a code no call reaches is not deliver's" 0 "PASS"

# --- the page, held to the runner ---

planted edited "$page" '/<!-- routed: let go -->/s/ 6, / /'
landed "$page" '1, 2, 3, 5, 10,' "a code the let-go line stops naming" \
  && expect "a code the let-go line stops naming is named" 1 "  6, from"

planted edited "$page" '/<!-- routed: let go -->/s/ 1, / 1, 19, /'
expect "a code an arm routes, named as let go too, is named" 1 "19 is routed by an arm, and the let-go line names it too"

planted edited "$page" '/<!-- routed: wait -->/s/ and 58//'
expect "a wait line short of the wait arm is named" 1 "the wait arm routes"

planted edited "$runner" '/^ *15|18|32|57|58)/s/15|18|/15|18|26|/'
expect "and a wait arm longer than the line" 1 "the wait arm routes [15 18 26 32 57 58]"

# --- a missing anchor is refused, never read as empty ---

planted edited "$runner" 's/^deliver() {/deliver_gone() {/'
expect "a runner with no deliver is refused" 3 "defines no \`deliver\`"

planted edited "$runner" '/^deliver_and_route()/,/^}/{/^ *[0-9|]*)/d;}'
expect "a deliver_and_route with no arm is refused" 3 "holds no arm"

planted edited "$page" 's/ <!-- routed: let go -->//'
expect "a page with no let-go line is refused" 3 "marks no let-go line"

planted edited "$page" 's/ <!-- routed: wait -->//'
expect "a page with no wait line is refused" 3 "marks no wait line"

# --- the paths can be named, so a case never reads this tree ---

a_lab
said=$(cd "$tmp/lab" && FOUNDRY_ROUTED_PAGE="$tmp/nowhere.md" sh bin/routed.sh 2>&1); code=$?
expect "a page named from outside is the one read" 3 "the page [$tmp/nowhere.md] could not be read"

printf '\n%s passed, %s failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
