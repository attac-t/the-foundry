#!/bin/bash
#
# Run every suite, then check the suites can fail.
#
# The second half is the part that matters. A green suite proves nothing until you have watched it
# go red, so we break the plugin one rule at a time and each break must take a suite down with it.
#

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="${TMPDIR:-/tmp}/kernel-audit-$$"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT

failed=0

# Record a failing audit.
bad() { failed=1; printf '  FAIL  %s\n' "$1"; }

#
# Determine if this system's `sh` is really bash.
#
# It is on macOS, and it is under Git Bash. bash in POSIX mode still accepts `&>`, `[[ =~ ]]` and
# `${BASH_SOURCE[0]}`, so a bashism put back on purpose changes nothing there and the mutation
# proves nothing. Only a runner whose `sh` is dash can answer these — which is the whole reason the
# matrix in gates.yml starts with ubuntu.
#
sh_is_bash() { [ -z "$(sh -c 'echo leak &>/dev/null' 2>/dev/null)" ]; }

# List the files a preflight could have left in the real temp directory.
strays() { ls "${TMPDIR:-/tmp}"/kernel-preflight-*.md 2>/dev/null | sort; }

# Count the lines in a list, treating the empty list as none.
tally() { printf '%s\n' "$1" | grep -c . ; }

marks_before=$(strays)

for suite in unjson memory install; do
  bash "$root/tests/$suite.sh" || failed=1
  echo
done

# --- break the reader ---

echo "audit — break the reader, the unjson suite must notice"

# Write a broken copy of the reader.
mutate() { sed "$2" "$root/hooks/lib/unjson.awk" > "$tmp/$1.awk" 2>"$tmp/$1.err"; }

# Determine if the mutant came out empty.
empty() { [ ! -s "$tmp/$1.awk" ]; }

# Determine if the mutant is unchanged.
same() { cmp -s "$tmp/$1.awk" "$root/hooks/lib/unjson.awk"; }

# Determine if the reader suite fails against the mutant.
noticed() { ! READER="$tmp/$1.awk" bash "$root/tests/unjson.sh" >/dev/null 2>&1; }

# Get why sed refused.
why() { head -1 "$tmp/$1.err"; }

#
# Break one rule and require the suite to notice.
#
# Three ways a mutant proves nothing, all seen for real in signal: sed fails, the output is empty,
# or the pattern never matched. `cmp` alone catches only the third — an empty file differs from the
# original too.
#
audit() {
  local name="$1" expr="$2" tag="$3"

  mutate "$tag" "$expr" || { bad "$name — sed failed, so this proves nothing: $(why "$tag")"; return; }
  empty "$tag"          && { bad "$name — the mutant is empty, so the suite failed for the wrong reason"; return; }
  same "$tag"           && { bad "$name — the break did not apply, so this proves nothing"; return; }
  noticed "$tag"        || { bad "$name — the suite passed against a broken reader"; return; }

  printf '  ok    %s\n' "$name"
}

audit "a reader that ignores depth is caught"    's|if (here() == path) { printf "%s", s; exit 0 }|if (s != "" \&\& path ~ /file_path/) { printf "%s", s; exit 0 }|' flat
audit "a reader that reads keys as values is caught" 's|if (substr(BUF, j, 1) == ":") { stack\[depth\] = s; i = j + 1; continue }|if (substr(BUF, j, 1) == ":") { stack[depth] = s }|' keyval
#
# Two exits, two mutations.
#
# "Not found" leaves through the line that closes the last object, and a truncated payload leaves
# through the one at the bottom. Mutating only the bottom one passed the whole suite, because no
# check reached it — the audit's own first job is catching audits that prove nothing.
#
audit "a reader that never says no is caught"    's|if (depth < 1) exit 1|if (depth < 1) exit 0|' neversays
audit "a reader that swallows a truncated payload is caught" 's|^  exit 1$|  exit 0|'             truncated
audit "a reader that leaves escapes in is caught" 's|out = out ((e in esc) ? esc\[e\] : e)|out = out "\\\\" e|' escapes

#
# The cursor guard, which only a clock can judge.
#
# Removing it does not make the reader wrong, it makes it never finish, and a suite with no bound on
# a runaway cannot tell that from a slow pass — it just hangs with it. macOS ships no `timeout`, so
# there the mutation is skipped rather than left to stall the runner for its full job budget.
#
if command -v timeout >/dev/null 2>&1; then
  audit "a reader that can trap its cursor is caught" 's|if (j == i) { i++; continue }|if (j == i) { i = i }|' cursor
else
  printf '  skip  a reader that can trap its cursor — no timeout here to bound the runaway\n'
fi

# --- break the lib scripts ---

echo
echo "audit — break a lib script, the memory suite must notice"

# Determine if the memory suite fails against a broken lib.
lib_caught() { ! LIB="$tmp/$1" bash "$root/tests/memory.sh" >/dev/null 2>&1; }

# Break one thing about a lib script and require the suite to notice.
wreck_lib() {
  local name="$1" tag="$2" file="$3" expr="$4"

  rm -rf "$tmp/$tag" && cp -R "$root/hooks/lib" "$tmp/$tag" || { bad "$name — could not copy lib"; return; }
  sed "$expr" "$root/hooks/lib/$file" > "$tmp/$tag/$file" || { bad "$name — sed failed"; return; }
  cmp -s "$tmp/$tag/$file" "$root/hooks/lib/$file" && { bad "$name — the break did not apply"; return; }
  lib_caught "$tag" || { bad "$name — the suite passed against a broken lib"; return; }

  printf '  ok    %s\n' "$name"
}

if sh_is_bash; then
  printf '  skip  a bash-only redirect put back — this sh is bash, where it is not a bug\n'
else
  wreck_lib "a bash-only redirect put back is caught" amp resolve-memory.sh 's|>/dev/null 2>&1|\&>/dev/null|'
fi

wreck_lib "an objective parser that keeps placeholders is caught" tbd extract-objective.sh 's|^  "\["\*"\]") exit 0 ;;|  "no-such-case") exit 0 ;;|'

# --- break the install ---

echo
echo "audit — break the install, the install suite must notice"

#
# The same rules one layer out, against a throwaway copy of the plugin.
#
# Every break below is one kernel actually shipped, or one line away from it. All of them left the
# reader and memory suites completely green, because those suites call the scripts themselves
# instead of reading how Claude Code is told to call them.
#

# Copy the plugin somewhere we can ruin it.
copy() { rm -rf "$tmp/$1" && cp -R "$root" "$tmp/$1"; }

# Determine if the install suite fails against the broken copy.
caught() { ! PLUGIN_ROOT="$tmp/$1" bash "$root/tests/install.sh" >/dev/null 2>&1; }

# Rewrite a file in place.
rewrite() { cat > "$1.new" && mv "$1.new" "$1"; }

# Break one thing about the install and require the suite to notice.
wreck() {
  local name="$1" tag="$2" break_it="$3"

  copy "$tag"             || { bad "$name — could not copy the plugin, so this proves nothing"; return; }
  "$break_it" "$tmp/$tag" || { bad "$name — the break did not apply, so this proves nothing"; return; }
  caught "$tag"           || { bad "$name — the suite passed against a broken install"; return; }

  printf '  ok    %s\n' "$name"
}

# Determine if this filesystem records an executable bit. Windows does not — tests/install.sh says
# why. Removing a bit that was never there mutates nothing, and a mutation that did not happen
# cannot prove the suite would notice it.
records_exec() {
  probe="$tmp/exec-probe"
  : > "$probe"
  chmod +x "$probe" 2>/dev/null
  [ -x "$probe" ] || return 1
  chmod -x "$probe" 2>/dev/null
  [ ! -x "$probe" ]
}

# The breaks.
unhook()   { chmod -x "$1/hooks/ground.sh"; }
crlf()     { awk '{ printf "%s\r\n", $0 }' "$1/hooks/ground.sh" | rewrite "$1/hooks/ground.sh"; }
unquote()  { sed 's/\\"//g' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
bare()     { sed 's|"command": "sh |"command": "|' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
unshell()  { grep -v '"shell"' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
unship()   { rm -f "$1/hooks/lib/unjson.awk"; }
rewire()   { sed 's|hooks/ground.sh|hooks/gone.sh|' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
unwire()   { grep -v 'consider.sh' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
bashism()  { sed 's|dirname "\$0"|dirname "${BASH_SOURCE[0]}"|' "$1/hooks/delegate.sh" | rewrite "$1/hooks/delegate.sh"; }
onecolumn(){ sed 's|column += (size > 1 && wide(code)) ? 2 : 1|column += 1|' "$1/hooks/lib/tables.awk" | rewrite "$1/hooks/lib/tables.awk"; }
saynothing(){ sed 's|if (!same) print start|if (0) print start|' "$1/hooks/lib/tables.awk" | rewrite "$1/hooks/lib/tables.awk"; }

if records_exec; then
  wreck "a hook that lost its executable bit is caught" nox unhook
else
  printf '  skip  a hook that lost its executable bit — this filesystem records no such bit\n'
fi

wreck "a hook checked out with CRLF is caught"        crlf   crlf
wreck "an unquoted plugin root is caught"             noquot unquote
wreck "a bare path with no interpreter is caught"     barep  bare
wreck "a hook that declares no shell is caught"       noshel unshell
wreck "a lib that did not ship is caught"             nolib  unship
wreck "hooks.json pointing at nothing is caught"      nofile rewire
wreck "a hook that ships but is never wired is caught" nowire unwire

# The table reader has one job a character count cannot do, so it gets its own break. Measuring
# every glyph as one column is the exact mistake that left eleven tables looking padded and reading
# crooked, and it is invisible to every other check here.
wreck "a table reader using the wrong ruler is caught"  onecol onecolumn
wreck "a table reader that never speaks is caught"      mute   saynothing

if sh_is_bash; then
  printf '  skip  a bash-only variable put back — this sh is bash, where it still resolves\n'
else
  wreck "a bash-only variable put back is caught"     bsrc   bashism
fi

# --- and the run cleans up after itself ---

echo
echo "audit — the run leaves nothing behind"

#
# Last, because everything above fires the preflight and this has to see all of it.
#
# The preflight writes a probe file to check the objective parser, and a probe that outlives the run
# is a file the next run may read instead of writing. signal collected thirty markers this way
# before anyone thought to look.
#
marks_after=$(strays)
[ "$marks_after" = "$marks_before" ] \
  && printf '  ok    no suite left a probe behind\n' \
  || bad "a suite left probes in ${TMPDIR:-/tmp} — $(tally "$marks_before") before, $(tally "$marks_after") now"

echo
[ "$failed" -eq 0 ] && echo "ALL GREEN" || echo "FAILURES ABOVE"
exit $failed
