#!/bin/bash
#
# Run every suite, then check the suites can fail.
#
# The second half is the part that matters. A green suite proves nothing until you have watched it
# go red, so we break the scorer one rule at a time and each break must take the suite down with it.
#

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="${TMPDIR:-/tmp}/signal-audit-$$"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT

failed=0

# Record a failing audit.
bad() { failed=1; printf '  FAIL  %s\n' "$1"; }

# Write a broken copy of the scorer.
mutate() { sed "$2" "$root/lib/score.awk" > "$tmp/$1.awk" 2>"$tmp/$1.err"; }

# Determine if the mutant came out empty.
empty() { [ ! -s "$tmp/$1.awk" ]; }

# Determine if the mutant is unchanged.
same() { cmp -s "$tmp/$1.awk" "$root/lib/score.awk"; }

# Determine if the scorer suite fails against the mutant.
noticed() { ! SCORER="$tmp/$1.awk" bash "$root/tests/score.sh" >/dev/null 2>&1; }

# Get why sed refused.
why() { head -1 "$tmp/$1.err"; }

#
# List the markers a suite could have left in the real temp directory.
#
# Only test-owned names are read. A marker under a real session id is a live turn's lock, and a check
# that goes red for someone else's correct behaviour is a check people learn to ignore.
#
strays() {
  ls "${TMPDIR:-/tmp}"/signal-install-*.mark      "${TMPDIR:-/tmp}"/signal-install-*.note \
     "${TMPDIR:-/tmp}"/signal-signal-test-*.mark  "${TMPDIR:-/tmp}"/signal-signal-test-*.note \
     "${TMPDIR:-/tmp}"/signal-signal-brief-*.note 2>/dev/null | sort
}

# Count the lines in a list, treating the empty list as none.
tally() { printf '%s\n' "$1" | grep -c . ; }

#
# Break one rule and require the suite to notice.
#
# Three ways a mutant proves nothing, all seen for real here: sed fails, the output is empty, or the
# pattern never matched. `cmp` alone catches only the third — an empty file differs from the original.
#
audit() {
  local name="$1" expr="$2" tag="$3"

  mutate "$tag" "$expr" || { bad "$name — sed failed, so this proves nothing: $(why "$tag")"; return; }
  empty "$tag"          && { bad "$name — the mutant is empty, so the suite failed for the wrong reason"; return; }
  same "$tag"           && { bad "$name — the break did not apply, so this proves nothing"; return; }
  noticed "$tag"        || { bad "$name — the suite passed against a broken scorer"; return; }

  printf '  ok    %s\n' "$name"
}

marks_before=$(strays)

for suite in score unjson guard brief install manifest; do
  bash "$root/tests/$suite.sh" || failed=1
  echo
done

echo "audit — break it on purpose, the suite must notice"

audit "a scorer that never blocks is caught"     's/^  exit (verdict.*/  exit 0/'                      nostop
audit "a dead long-word check is caught"         's/^  if (long_pct > long_block).*/  dead = 0/'       longblock
audit "a dead sentence check is caught"          's/^  if (longest  > sent_block).*/  dead = 0/'       sentblock
audit "a dead word-budget check is caught"       's/^  if (prose_words > words_block).*/  dead = 0/'   wordblock
audit "a dead long-word warn band is caught"     's/^  if (long_pct > long_warn).*/  dead = 0/'        longwarn
audit "a dead sentence warn band is caught"      's/^  if (longest  > sent_warn).*/  dead = 0/'        sentwarn
audit "a dead word-budget warn band is caught"   's/^  if (prose_words > words_warn).*/  dead = 0/'    wordwarn
audit "a table left out of long words is caught" 's/^  tally(tbuf)/  dead = 0/'                        table
audit "the sh-sound exception is tested"         's@ && t !~ /\[tcsx\](ia|io)\[nl\]/@@'                shsound
audit "the -tio ending carve-out is tested"      's@(ia|io)\[nl\]@(ia|io)@'                            tioend
audit "a dead blank-line boundary is caught"     's|^/\^\[ \\t\]\*\$/  *{ pbuf = pbuf EDGE; next }|/^ZZZNEVER$/ { next }|' blankline
audit "the wrap dodge staying shut is tested"    's|^                                 { pbuf = pbuf " " line }|{ if (line ~ /[A-Za-z0-9)]$/) line = line "."; pbuf = pbuf " " line }|' wrap

echo
echo "audit — break the install, the install suite must notice"

#
# The same rule one layer out, against a throwaway copy of the plugin.
#
# Every break below is one that actually shipped, or one line away from it. Each left the scorer,
# the reader and the guard suites completely green, because all three call the hook themselves
# instead of reading how Claude Code is told to call it.
#

# Copy the plugin somewhere we can ruin it.
copy() { rm -rf "$tmp/$1" && cp -R "$root" "$tmp/$1"; }

# Determine if a suite fails against the broken copy.
caught()  { ! PLUGIN_ROOT="$tmp/$1" bash "$root/tests/install.sh" >/dev/null 2>&1; }
guarded() { ! PLUGIN_ROOT="$tmp/$1" bash "$root/tests/guard.sh"   >/dev/null 2>&1; }
briefed() { ! PLUGIN_ROOT="$tmp/$1" bash "$root/tests/brief.sh"   >/dev/null 2>&1; }

# Rewrite a file in place.
rewrite() { cat > "$1.new" && mv "$1.new" "$1"; }

# Break one thing about the install and require a suite to notice. Defaults to the install suite.
wreck() {
  local name="$1" tag="$2" break_it="$3" notices="${4:-caught}"

  copy "$tag"      || { bad "$name — could not copy the plugin, so this proves nothing"; return; }
  "$break_it" "$tmp/$tag" || { bad "$name — the break did not apply, so this proves nothing"; return; }
  "$notices" "$tag" || { bad "$name — the suite passed against a broken install"; return; }

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

# The breaks. Each sed replaces the one line it names, except unquote, which takes the quotes off
# all four commands the way a hand-edited hooks.json loses them. Only the Stop wire is ever fired
# against a path with a space in it, so that is the one that turns the suite red.
unhook()  { chmod -x "$1/hooks/signal.sh"; }
crlf()    { awk '{ printf "%s\r\n", $0 }' "$1/hooks/signal.sh" | rewrite "$1/hooks/signal.sh"; }
unquote() { sed 's/\\"//g' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
unship()  { rm -f "$1/lib/score.awk"; }
untrust() { sed 's#^remember || {#remember; false \&\& {#' "$1/hooks/signal.sh" | rewrite "$1/hooks/signal.sh"; }
rewire()  { sed 's|hooks/signal.sh|hooks/gone.sh|' "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
unbrief() { sed 's|hooks/brief.sh|hooks/gone.sh|'  "$1/hooks/hooks.json" | rewrite "$1/hooks/hooks.json"; }
unnote()  { sed 's|^note |: |'                     "$1/hooks/signal.sh"  | rewrite "$1/hooks/signal.sh"; }
unsay()   { sed 's|,"systemMessage":"%s"||'        "$1/hooks/signal.sh"  | rewrite "$1/hooks/signal.sh"; }
unread()  { sed 's|^last=.*|last=|'                "$1/hooks/brief.sh"   | rewrite "$1/hooks/brief.sh"; }
unturn()  { sed '/in your last message/d'          "$1/hooks/brief.sh"   | rewrite "$1/hooks/brief.sh"; }

audit_the_executable_bit() {
  records_exec || {
    printf '  skip  a hook that lost its executable bit — this filesystem records no such bit\n'
    return
  }
  wreck "a hook that lost its executable bit is caught" nox unhook
}
audit_the_executable_bit

wreck "a hook checked out with CRLF is caught"        nolf   crlf
wreck "an unquoted plugin root is caught"             noquot unquote
wreck "a lib that did not ship is caught"             nolib  unship
wreck "hooks.json pointing at nothing is caught"      nofile rewire

#
# The forward correction, broken at each end. Both ends fail silently: signal goes on scoring every
# reply and blocking the tail, looking alive while the half that runs first is gone.
#
wreck "a brief that lost its wire is caught"          nobrief unbrief
wreck "a Stop hook that leaves no note is caught"     nonote  unnote guarded

# The block that shipped for months. The agent was told to write again and the reader was told
# nothing, so two replies arrived and only one of them counted.
wreck "a block the reader never hears is caught"      nosay   unsay  guarded
wreck "a block taken on trust is caught"              notrust untrust guarded
wreck "a brief that never reads the note is caught"   noread  unread briefed

#
# The turn rule, which nothing else can mark. `Stop` is handed one message, so a turn that answered
# twice scores as one reply and passes. Drop the line and every count stays green.
#
wreck "a brief that dropped the turn rule is caught"  noturn  unturn briefed

echo
echo "audit — the run leaves nothing behind"

#
# Last, because everything above fires the hook and this has to see all of it.
#
# signal.sh drops a marker in the temp directory every time it blocks, and these suites block on
# purpose, over and over. Nothing ever comes back for them: cleanup.sh runs at SessionEnd, and no
# session ends under a test's id. Thirty had collected here before anyone thought to look.
#
marks_after=$(strays)
[ "$marks_after" = "$marks_before" ] \
  && printf '  ok    no suite left a marker behind\n' \
  || bad "a suite left markers in ${TMPDIR:-/tmp} — $(tally "$marks_before") before, $(tally "$marks_after") now"

echo
[ "$failed" -eq 0 ] && echo "ALL GREEN" || echo "FAILURES ABOVE"
exit $failed
