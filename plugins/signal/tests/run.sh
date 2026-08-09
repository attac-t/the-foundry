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

for suite in score unjson guard manifest; do
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
audit "a dead blank-line boundary is caught"     's|^/\^\[ \\t\]\*\$/  *{ pbuf = pbuf SEP; next }|/^ZZZNEVER$/ { next }|' blankline
audit "the wrap dodge staying shut is tested"    's|^                                 { pbuf = pbuf " " line }|{ if (line ~ /[A-Za-z0-9)]$/) line = line "."; pbuf = pbuf " " line }|' wrap

echo
[ "$failed" -eq 0 ] && echo "ALL GREEN" || echo "FAILURES ABOVE"
exit $failed
