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

# What a suite said to the last mutant it met, kept so a row can read which check went red. #1144.
heard="$tmp/heard"

main() {
  local strays_before
  strays_before=$(strays)

  run_every_suite
  audit_the_reader
  audit_the_lib_scripts
  audit_the_install
  audit_the_label
  audit_the_cleanup "$strays_before"
  audit_the_tally
  audit_the_bound
  audit_the_mode_guard

  report
}

# Record a failing audit.
bad() { failed=1; printf '  FAIL  %s\n' "$1"; }

#
# A mutant that never answers is not a mutant the suite caught. Copied from floor's audit rather
# than shared, because a plugin ships alone and a suite needing a
# sibling breaks the thing it tests.
#
# Timeout exits 124 when it kills one. Inverting that gives zero, which is this file's word for the
# suite noticing, so a mutant that hung would be filed as caught.
#
moot() { [ "$failed" -eq 0 ] && failed=3; printf '  MOOT  %s\n' "$1"; }

# Eight times the slowest mutant measured here, which was about fifteen seconds. A deadline reached
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

  timeout "$seconds" "$@" >"$heard" 2>&1
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

  "$@" >"$heard" 2>&1 &
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
  audit_the_echo

  wreck_lib "an objective parser that keeps placeholders is caught" tbd extract-objective.sh 's|^  "\["\*"\]") exit 0 ;;|  "no-such-case") exit 0 ;;|' 'a placeholder is not a goal'

  # The run rung, both ways: a rung that fires on a directory that is not there, and a rung that
  # never fires at all. Every memory hook goes quiet rather than loud on the first.
  wreck_lib "a resolver that trusts a deleted run is caught"  ghost  resolve-memory.sh 's|\[ -d "$FOUNDRY_RUN" \]|\[ -n "$FOUNDRY_RUN" \]|' 'a run that is gone falls back to the branch'
  wreck_lib "a resolver that ignores an active run is caught" norung resolve-memory.sh 's|if \[ -n "${FOUNDRY_RUN:-}" \] |if \[ -z "${FOUNDRY_RUN:-}" \] |' 'an active run outranks the base'

  # The folder a hook names, dropped: memory is read where the hook runs again. #1137.
  wreck_lib "a resolver that drops the session's folder is caught" nosess resolve-memory.sh 's|SESSION="${1:-}"|SESSION=|' 'named a worktree from the main checkout, it answers that branch in full'

  # A base that starts with a backslash, read as relative again, is joined under the folder. #1162.
  wreck_lib "a resolver that joins a rooted base is caught" noarm resolve-memory.sh 's/|\\\\\*)/)/' 'and a rooted one'
}

# Both of resolve-memory.sh's redirects at once. The rule is never `&>` anywhere in that file, so a
# break that put the bashism back in one place would leave the other unguarded. The leading space
# keeps it off the header line, which quotes the redirect it forbids.
audit_the_redirect() {
  sh_is_bash && {
    printf '  skip  a bash-only redirect put back — this sh is bash, where it is not a bug\n'
    return
  }
  # No check names the redirect. The guard memory.sh keeps for this bashism is the label.
  wreck_lib "a bash-only redirect put back is caught" amp resolve-memory.sh 's| >/dev/null 2>&1| \&>/dev/null|' 'the answer never carries a path to git'
}

# `echo` put back on the answer. Dash reads `\\` in it as one backslash, so a UNC base cannot leave
# whole. Where `sh` is bash, the probe cannot say if its `echo` reads escapes, so this skips. #1162.
audit_the_echo() {
  sh_is_bash && {
    printf '  skip  echo put back on the answer — this sh is bash, and the probe cannot say whether its echo reads escapes\n'
    return
  }
  wreck_lib "echo put back on the answer is caught" echoback resolve-memory.sh 's/answer() { printf [^"]*"/answer() { echo "/' 'and a UNC base, which leaves whole wherever echo reads escapes'
}

# Break one thing about a lib script and require the suite to fail the check its row names.
wreck_lib() {
  local name="$1" tag="$2" file="$3" expr="$4" label="$5"

  rm -rf "$tmp/$tag" && cp -R "$root/hooks/lib" "$tmp/$tag" || { bad "$name — could not copy lib"; return; }
  sed "$expr" "$root/hooks/lib/$file" > "$tmp/$tag/$file" || { bad "$name — sed failed"; return; }
  cmp -s "$tmp/$tag/$file" "$root/hooks/lib/$file" && { bad "$name — the break did not apply"; return; }
  lib_caught "$tag"
  case $? in
    1) bad  "$name — the suite passed against a broken lib"; return ;;
    2) moot "$name — the mutant never answered, so this proves nothing"; return ;;
  esac
  failed_on "$label" || { bad "$name — $(what_failed_instead "$label")"; return; }

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

  wreck "a hook checked out with CRLF is caught"        crlf   crlf 'carriage returns'
  wreck "an unquoted plugin root is caught"             noquot unquote 'every plugin root is quoted'
  wreck "a bare path with no interpreter is caught"     barep  bare 'consider.sh runs a bare path'
  wreck "a hook that declares no shell is caught"       noshel unshell 'declares its shell'
  # No check names a missing lib. The preflight is what speaks up, so its silence is the label.
  wreck "a lib that did not ship is caught"             nolib  unship 'preflight is silent when healthy'
  wreck "hooks.json pointing at nothing is caught"      nofile rewire 'hooks.json wires gone.sh, which did not ship'
  wreck "a hook that ships but is never wired is caught" nowire unwire 'consider.sh ships but nothing wires it'
  wreck "a key that is not hooks is caught"              style  restyle 'hooks.json carries "outputStyle", which Claude Code drops with a warning at every start'
  wreck "an edit hook naming a standard by the path as handed is caught" stdabs stdabs 'and names craft-sh for a shipped script, by its absolute path'
  wreck "an edit hook skipping by the path as handed is caught" skipabs skipabs 'and nudges code in a work tree under a folder named tests, #1143'
  wreck "an edit hook speaking outside a work tree is caught" outwt anywhere 'consider is quiet outside every work tree'
  wreck "a ground hook that forgets a compaction is caught" forget forgets 'and to a compaction'
  wreck "a ground hook that demands after a compaction is caught" insist insists 'after a compaction ground does not demand'
  wreck "a remember hook that never reads the session's folder is caught" remcwd remembers_here "from the main checkout, remember loads the worktree's memory"
  wreck "a prompt hook that never reads the session's folder is caught" procwd prompts_here "and prompt echoes the worktree's objective"
  wreck "a verify hook that never reads the session's folder is caught" vercwd verifies_here "and verify holds the turn on the worktree's blueprint"
  wreck "a protected check asked of the hook's own folder is caught" protect protects_here "and names the worktree's path for progress, though the checkout is on main"

  sh_is_bash && {
    printf '  skip  a bash-only variable put back — this sh is bash, where it still resolves\n'
    return
  }
  # No check names a bashism. Under dash the variable is a bad substitution, so the prompt hook
  # cannot find its lib, and the objective goes unsaid. That is the check this row reads.
  wreck "a bash-only variable put back is caught"       bsrc   bashism 'the prompt hook echoes the objective'
}

audit_the_executable_bit() {
  records_exec || {
    printf '  skip  a hook that lost its executable bit — this filesystem records no such bit\n'
    return
  }
  wreck "a hook that lost its executable bit is caught" nox unhook 'not executable' drops-a-mode
}

#
# Break one thing about the install and require the suite to fail the check its row names.
#
# A break that drops a hook's executable bit fails the suite for that alone, whatever else it broke,
# so it is refused unless its call says the bit is the thing it breaks. #1142.
#
# A suite red only on other checks is a row that proved something else. #1144.
wreck() {
  local name="$1" tag="$2" break_it="$3" label="$4" breaks_a_mode="${5:-}"

  copy "$tag"             || { bad "$name — could not copy the plugin, so this proves nothing"; return; }
  "$break_it" "$tmp/$tag" || { bad "$name — the break did not apply, so this proves nothing"; return; }
  [ -n "$breaks_a_mode" ] || modes_held "$tag" \
    || { bad "$name — the break dropped a hook's executable bit, so the suite failed for that"; return; }
  caught "$tag"
  case $? in
    1) bad  "$name — the suite passed against a broken install"; return ;;
    2) moot "$name — the mutant never answered, so this proves nothing"; return ;;
  esac
  failed_on "$label" || { bad "$name — $(what_failed_instead "$label")"; return; }

  printf '  ok    %s\n' "$name"
}

#
# Whether the suite the last mutant met failed the named check. A label is a check's own name: it
# starts a FAIL line's text and ends with the line, or at the dash before the line's detail. Each
# is matched whole, as a fixed string.
#
failed_on() {
  want="  FAIL  $1" awk '$0 == ENVIRON["want"] || index($0, ENVIRON["want"] " — ") == 1 { found = 1 }
                        END { exit !found }' "$heard"
}

# Say which check a row wanted, and the first one its suite failed instead.
what_failed_instead() { printf 'wanted [%s] to fail, and the first to fail was [%s]' "$1" "$(first_failure)"; }

# The name of the first check the last suite failed, cut where its detail begins.
first_failure() {
  awk 'index($0, "  FAIL  ") == 1 { line = substr($0, 9); cut = index(line, " — ")
                                    print (cut ? substr(line, 1, cut - 1) : line); exit }' "$heard"
}

# Copy the plugin somewhere we can ruin it.
copy() { rm -rf "$tmp/$1" && cp -R "$root" "$tmp/$1"; }

# Whether the broken copy kept every executable bit the plugin ships, on each script at any depth,
# as the suite reads them. Where this host keeps no bit there is nothing to hold, and no refusal.
modes_held() {
  records_exec || return 0
  ! scripts_that_lost_their_bit "$1" | grep -q .
}

# Each script the plugin ships executable that the broken copy still holds, without the bit.
scripts_that_lost_their_bit() {
  find "$root/hooks" -name '*.sh' -type f | while read -r script; do
    lost_its_bit "$script" "$tmp/$1/hooks/${script#"$root"/hooks/}" && printf '%s\n' "$script"
  done
}

lost_its_bit() { [ -x "$1" ] && [ -e "$2" ] && [ ! -x "$2" ]; }

# Determine if the install suite fails against the broken copy.
caught() { red_against install.sh PLUGIN_ROOT="$tmp/$1"; }

# Rewrite a file by moving a new one over it, which takes the umask's mode: right for hooks.json.
rewrite() { cat > "$1.new" && mv "$1.new" "$1"; }

# Rewrite a file through itself, so it keeps its mode. `rewrite` moves a new file over the old, and
# a hook that lost its executable bit fails the suite whatever else the break did.
rewrite_in_place() { cat > "$1.new" && cat "$1.new" > "$1" && rm -f "$1.new"; }

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
crlf()     { awk '{ printf "%s\r\n", $0 }' "$1/hooks/ground.sh" | rewrite_in_place "$1/hooks/ground.sh"; }
unquote()  { sed 's/\\"//g' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
bare()     { sed 's|"command": "sh |"command": "|' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
unshell()  { grep -v '"shell"' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
unship()   { rm -f "$1/hooks/lib/unjson.awk"; }
rewire()   { sed 's|hooks/ground.sh|hooks/gone.sh|' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
unwire()   { grep -v 'consider.sh' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
restyle()  { awk '/^  "hooks": \{$/ { print "  \"outputStyle\": \"kernel:craftsman\"," } { print }' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
bashism()  { sed 's|dirname "\$0"|dirname "${BASH_SOURCE[0]}"|'  "$1/hooks/prompt.sh" | rewrite_in_place "$1/hooks/prompt.sh"; }

# The edit hook before #1141, #1143 and #1130. `stdabs` and `skipabs` each reach one case. `anywhere`
# reaches all four quiet cases and its row names one, so the other three stay unpinned.
stdabs()   { sed 's#standard_for "$IN_TREE"#standard_for "$FILE"#' "$1/hooks/consider.sh" | rewrite_in_place "$1/hooks/consider.sh"; }
skipabs()  { sed 's#"$IN_TREE" | grep -qE#"$FILE" | grep -qE#' "$1/hooks/consider.sh" | rewrite_in_place "$1/hooks/consider.sh"; }
anywhere() { grep -vF 'can_be_committed "$FILE" || exit 0' "$1/hooks/consider.sh" | rewrite_in_place "$1/hooks/consider.sh"; }

# The two ways the ground hook can fail #1109: not asked after a compaction, or demanding there.
forgets() { sed 's#"matcher": "startup|clear|compact"#"matcher": "startup|clear"#' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
insists() { sed 's#= compact \]#= never ]#' "$1/hooks/ground.sh" | rewrite_in_place "$1/hooks/ground.sh"; }

# How a hook reads another checkout's memory, #1137: one of the three never reads the session's
# folder, or the protected check asks the folder the hook runs in.
remembers_here() { sed 's#-v path=cwd#-v path=nowhere#' "$1/hooks/remember.sh" | rewrite_in_place "$1/hooks/remember.sh"; }
prompts_here()   { sed 's#-v path=cwd#-v path=nowhere#' "$1/hooks/prompt.sh" | rewrite_in_place "$1/hooks/prompt.sh"; }
verifies_here()  { sed 's#"$(field cwd)"#""#' "$1/hooks/verify.sh" | rewrite_in_place "$1/hooks/verify.sh"; }
protects_here()  { sed 's#git -C "${session:-.}" branch#git branch#' "$1/hooks/prompt.sh" | rewrite_in_place "$1/hooks/prompt.sh"; }

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


# The tally every check reports through. A break that empties a suite used to turn it green, and no
# audit could see it, because the audit reads the same exit code.
audit_the_tally() {
  ( . "$root/tests/lib.sh"; summary 'a suite that ran nothing' ) >/dev/null 2>&1 \
    && bad "a suite that ran nothing passed" \
    || printf '  ok    a suite that ran nothing does not pass\n'
}

# The bound itself, because no mutant has ever hung and an unused guard is the one that rots.
audit_the_bound() {
  ( deadline=1; bounded "$deadline" sleep 5 )

  [ "$?" -eq 2 ] && { printf '  ok    a mutant that never answers is bounded\n'; return; }
  bad "a mutant that never answers was not bounded"
}

# The mode guard, driven, since the one break that drops a bit opts out of it. #1142.
audit_the_mode_guard() {
  records_exec || { printf '  skip  the mode guard — no executable bit is kept here\n'; return; }
  copy guard && chmod -x "$tmp/guard/hooks/ground.sh" \
    || { bad "the mode guard — no copy to drive it, so this proves nothing"; return; }
  modes_held guard && { bad "a copy whose hook lost its executable bit reads as held"; return; }
  printf '  ok    a copy whose hook lost its executable bit is refused\n'
}

# A row whose break turns a check red, but names one its suite passes, must fail and name both. #1144.
audit_the_label() {
  local said
  said=$(failed=0; wreck "a decoy" decoy crlf "the prompt hook echoes the objective"; echo "failed=$failed")

  never_answered "$said" && { moot "a row whose break misses its own check — the decoy never answered"; return; }
  names_both "$said" || { bad "a row whose break misses its own check reads as caught — $said"; return; }
  printf '  ok    a row whose break misses its own check fails, naming both\n'
}

# Whether the bound ended the decoy's mutant before its suite answered.
never_answered() { case $1 in *"MOOT  a decoy"*) return 0 ;; esac; return 1; }

# Whether the decoy's row failed, naming the check it wanted and the first that failed instead.
names_both() {
  case $1 in
    *"wanted [the prompt hook echoes the objective] to fail, and the first to fail was ["?*"]"*"failed=1") return 0 ;;
  esac
  return 1
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
