#!/bin/bash
#
# Run every suite, then check the suites can fail.
#
# The second half is the part that matters. A green suite proves nothing until you have watched it
# go red, so we break the plugin one rule at a time and each break must take a suite down with it.
#
# `set -e` stays off on purpose. A red suite must not stop the ones behind it, or the first failure
# hides every other and none of the audits run at all.
#

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="${TMPDIR:-/tmp}/kernel-audit-$$"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT

failed=0

main() {
  local strays_before
  strays_before=$(strays)

  run_every_suite
  audit_the_reader
  audit_the_lib_scripts
  audit_the_install
  audit_the_cleanup "$strays_before"
  audit_the_tally
  audit_the_bound

  report
}

# Record a failing audit.
bad() { failed=1; printf '  FAIL  %s\n' "$1"; }

#
# A mutant that never answers is not a mutant the suite caught. Copied from floor's audit rather
# than shared, because a plugin ships alone and a suite needing a
# sibling breaks the thing it tests.
#
# Timeout exits 124 when it kills one. Inverting that gives zero,
# which is this file's word for the suite noticing, so
# a mutant that hung would be filed as caught.
#
moot() { [ "$failed" -eq 0 ] && failed=3; printf '  MOOT  %s\n' "$1"; }

# Eight times the slowest mutant measured here, which
# was about fifteen seconds. A deadline reached
# too early is a verdict nobody earned.
deadline=${FOUNDRY_AUDIT_DEADLINE:-120}

bounded() {
  local seconds="$1"
  shift

  command -v timeout >/dev/null 2>&1 && { timed "$seconds" "$@"; return; }

  polled "$seconds" "$@"
}

# A real 2 from the command reads as a deadline. These suites answer 0 or 1, so the collision is a
# shape they do not have.
timed() {
  local seconds="$1" said
  shift

  timeout "$seconds" "$@" >/dev/null 2>&1
  said=$?

  [ "$said" -eq 124 ] && return 2
  return "$said"
}

# macOS ships no timeout unless someone installed the GNU tools, so without
# this there is no bound at all there. Wait with a deadline is bash
# 4.3 and macOS ships 3.2, which is the same platform twice.
polled() {
  local seconds="$1" job waited=0
  shift

  "$@" >/dev/null 2>&1 &
  job=$!

  while kill -0 "$job" 2>/dev/null; do
    [ "$waited" -ge "$seconds" ] && { kill -9 "$job" 2>/dev/null; wait "$job" 2>/dev/null; return 2; }
    sleep 1
    waited=$((waited + 1))
  done

  wait "$job"
}

# One shape for every noticer here. The suite must go red against the mutant, and 2 says it never
# answered at all — which is not the suite answering badly.
red_against() {
  local suite="$1" said
  shift

  bounded "$deadline" env "$@" bash "$root/tests/$suite"
  said=$?

  [ "$said" -eq 2 ] && return 2
  [ "$said" -eq 0 ] && return 1
  return 0
}

#
# Determine if this system's `sh` is really bash.
#
# It is on macOS, and it is under Git Bash. bash in POSIX mode still accepts `&>`, `[[ =~ ]]` and
# `${BASH_SOURCE[0]}`, so a bashism put back on purpose changes nothing there and the mutation
# proves nothing. Only a runner whose `sh` is dash can answer these — which is the whole reason the
# matrix in gates.yml starts with ubuntu.
#
sh_is_bash() { [ -z "$(sh -c 'echo leak &>/dev/null' 2>/dev/null)" ]; }

# Run each suite in its own bash, and remember whether any of them went red.
run_every_suite() {
  local suite
  for suite in unjson memory install; do
    bash "$root/tests/$suite.sh" || failed=1
    echo
  done
}

audit_the_reader() {
  echo "audit — break the reader, the unjson suite must notice"

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
  # The cursor guard, and the one break whose premise depends on the awk underneath.
  #
  # Removing it lets the cursor stand still. mawk then finishes with the wrong answer and the suite
  # catches it. BusyBox awk finishes with the *right* answer, so the same edit changes nothing it can
  # see — and requiring a catch there reported the suite as broken when nothing was.
  #
  # So prove the break bites here before demanding it be caught. Scoped to this one mutation on
  # purpose: a probe cheap enough to run against every break would wrongly clear the ones that only
  # show on inputs it does not carry, `truncated` among them.
  #
  cursor_break='s|if (j == i) { i++; continue }|if (j == i) { i = i }|'

  mutate cursor "$cursor_break"
  changes_the_answer cursor || {
    printf '  skip  a reader that can trap its cursor — this awk finishes the mutant with the right answer\n'
    return
  }

  audit "a reader that can trap its cursor is caught" "$cursor_break" cursor
}

# Read a known nested value with a given reader.
probe_reader() {
  printf '%s' '{"tool_input":{"file_path":"ok"}}' | awk -f "$1" -v path=tool_input.file_path 2>/dev/null
}

# Determine if a mutant answers differently from the shipped reader.
changes_the_answer() {
  [ "$(probe_reader "$tmp/$1.awk")" != "$(probe_reader "$root/hooks/lib/unjson.awk")" ]
}

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

audit_the_lib_scripts() {
  echo
  echo "audit — break a lib script, the memory suite must notice"

  audit_the_redirect

  wreck_lib "an objective parser that keeps placeholders is caught" tbd extract-objective.sh 's|^  "\["\*"\]") exit 0 ;;|  "no-such-case") exit 0 ;;|'

  # The run rung, both ways: a rung that fires on a directory that is not there, and a rung that
  # never fires at all. Every memory hook goes quiet rather than loud on the first.
  wreck_lib "a resolver that trusts a deleted run is caught"  ghost  resolve-memory.sh 's|\[ -d "$FOUNDRY_RUN" \]|\[ -n "$FOUNDRY_RUN" \]|'
  wreck_lib "a resolver that ignores an active run is caught" norung resolve-memory.sh 's|if \[ -n "${FOUNDRY_RUN:-}" \] |if \[ -z "${FOUNDRY_RUN:-}" \] |'
}

# Both of resolve-memory.sh's redirects at once. The rule is never `&>` anywhere in that file, so a
# break that put the bashism back in one place would leave the other unguarded. The leading space
# keeps it off the header line, which quotes the redirect it forbids.
audit_the_redirect() {
  sh_is_bash && {
    printf '  skip  a bash-only redirect put back — this sh is bash, where it is not a bug\n'
    return
  }
  wreck_lib "a bash-only redirect put back is caught" amp resolve-memory.sh 's| >/dev/null 2>&1| \&>/dev/null|'
}

# Break one thing about a lib script and require the suite to notice.
wreck_lib() {
  local name="$1" tag="$2" file="$3" expr="$4"

  rm -rf "$tmp/$tag" && cp -R "$root/hooks/lib" "$tmp/$tag" || { bad "$name — could not copy lib"; return; }
  sed "$expr" "$root/hooks/lib/$file" > "$tmp/$tag/$file" || { bad "$name — sed failed"; return; }
  cmp -s "$tmp/$tag/$file" "$root/hooks/lib/$file" && { bad "$name — the break did not apply"; return; }
  lib_caught "$tag"
  case $? in
    1) bad  "$name — the suite passed against a broken lib"; return ;;
    2) moot "$name — the mutant never answered, so this proves nothing"; return ;;
  esac

  printf '  ok    %s\n' "$name"
}

# Determine if the memory suite fails against a broken lib.
lib_caught() { red_against memory.sh LIB="$tmp/$1"; }

#
# The same rules one layer out, against a throwaway copy of the plugin.
#
# Every break below is one kernel actually shipped, or one line away from it. All of them left the
# reader and memory suites completely green, because those suites call the scripts themselves
# instead of reading how Claude Code is told to call them.
#
audit_the_install() {
  echo
  echo "audit — break the install, the install suite must notice"

  audit_the_executable_bit

  wreck "a hook checked out with CRLF is caught"        crlf   crlf
  wreck "an unquoted plugin root is caught"             noquot unquote
  wreck "a bare path with no interpreter is caught"     barep  bare
  wreck "a hook that declares no shell is caught"       noshel unshell
  wreck "a lib that did not ship is caught"             nolib  unship
  wreck "hooks.json pointing at nothing is caught"      nofile rewire
  wreck "a hook that ships but is never wired is caught" nowire unwire

  sh_is_bash && {
    printf '  skip  a bash-only variable put back — this sh is bash, where it still resolves\n'
    return
  }
  wreck "a bash-only variable put back is caught"       bsrc   bashism
}

audit_the_executable_bit() {
  records_exec || {
    printf '  skip  a hook that lost its executable bit — this filesystem records no such bit\n'
    return
  }
  wreck "a hook that lost its executable bit is caught" nox unhook
}

# Break one thing about the install and require the suite to notice.
wreck() {
  local name="$1" tag="$2" break_it="$3"

  copy "$tag"             || { bad "$name — could not copy the plugin, so this proves nothing"; return; }
  "$break_it" "$tmp/$tag" || { bad "$name — the break did not apply, so this proves nothing"; return; }
  caught "$tag"          
  case $? in
    1) bad  "$name — the suite passed against a broken install"; return ;;
    2) moot "$name — the mutant never answered, so this proves nothing"; return ;;
  esac

  printf '  ok    %s\n' "$name"
}

# Copy the plugin somewhere we can ruin it.
copy() { rm -rf "$tmp/$1" && cp -R "$root" "$tmp/$1"; }

# Determine if the install suite fails against the broken copy.
caught() { red_against install.sh PLUGIN_ROOT="$tmp/$1"; }

# Rewrite a file in place.
rewrite() { cat > "$1.new" && mv "$1.new" "$1"; }

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

# The breaks. The ones that rewrite hooks.json rewrite every hook in it, on purpose — the wiring is
# one artefact, and the bug kernel shipped was never confined to a single line of it.
unhook()   { chmod -x "$1/hooks/ground.sh"; }
crlf()     { awk '{ printf "%s\r\n", $0 }' "$1/hooks/ground.sh" | rewrite "$1/hooks/ground.sh"; }
unquote()  { sed 's/\\"//g' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
bare()     { sed 's|"command": "sh |"command": "|' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
unshell()  { grep -v '"shell"' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
unship()   { rm -f "$1/hooks/lib/unjson.awk"; }
rewire()   { sed 's|hooks/ground.sh|hooks/gone.sh|' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
unwire()   { grep -v 'consider.sh' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
bashism()  { sed 's|dirname "\$0"|dirname "${BASH_SOURCE[0]}"|' "$1/hooks/delegate.sh" | rewrite "$1/hooks/delegate.sh"; }

#
# Last, because everything above fires the preflight and this has to see all of it.
#
# The preflight writes a probe file to check the objective parser, and a probe that outlives the run
# is a file the next run may read instead of writing. signal collected thirty markers this way
# before anyone thought to look.
#
audit_the_cleanup() {
  local before="$1" after

  echo
  echo "audit — the run leaves nothing behind"

  after=$(strays)
  [ "$after" = "$before" ] \
    && printf '  ok    no suite left a probe behind\n' \
    || bad "a suite left probes in ${TMPDIR:-/tmp} — $(tally "$before") before, $(tally "$after") now"
}

# List the files a preflight could have left in the real temp directory.
strays() { ls "${TMPDIR:-/tmp}"/kernel-preflight-*.md 2>/dev/null | sort; }

# Count the lines in a list, treating the empty list as none.
tally() { printf '%s\n' "$1" | grep -c . ; }


# The tally every check reports through. A break that empties a
# suite used to turn it green, and no audit could see it,
# because the audit reads the same exit code.
audit_the_tally() {
  ( . "$root/tests/lib.sh"; summary 'a suite that ran nothing' ) >/dev/null 2>&1 \
    && bad "a suite that ran nothing passed" \
    || printf '  ok    a suite that ran nothing does not pass\n'
}

# The bound itself, because no mutant has ever hung
# and an unused guard is the one
# that rots.
audit_the_bound() {
  ( deadline=1; bounded "$deadline" sleep 5 )

  [ "$?" -eq 2 ] && { printf '  ok    a mutant that never answers is bounded\n'; return; }
  bad "a mutant that never answers was not bounded"
}

# Say how it went, and leave with the verdict.
report() {
  echo
  [ "$failed" -eq 0 ] && echo "ALL GREEN"
  [ "$failed" -eq 1 ] && echo "FAILURES ABOVE"
  [ "$failed" -eq 3 ] && echo "PROVED NOTHING — the experiments above never ran"
  exit "$failed"
}

main "$@"
