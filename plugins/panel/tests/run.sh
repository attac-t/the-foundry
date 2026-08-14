#!/bin/bash
#
# Run the suite, then check the suite can fail.
#
# A green suite proves nothing until you have watched it go red, so each rule is broken on purpose
# and every break must take the suite down with it.
#

set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="${TMPDIR:-/tmp}/panel-audit-$$"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT

failed=0
bad() { failed=1; printf '  FAIL  %s\n' "$1"; }

bash "$root/tests/chain.sh" || failed=1
echo

echo "audit — break the chain, the suite must notice"

caught() { ! RUNNER="$tmp/$1/bin/verdicts.sh" bash "$root/tests/chain.sh" >/dev/null 2>&1; }

#
# Break one rule and require the suite to notice.
#
# Three ways a mutant proves nothing: sed fails, the output comes out empty, or the pattern never
# matched. `cmp` alone catches only the third — an empty file differs from the original too.
#
wreck() {
  local name="$1" tag="$2" mutation="$3"

  rm -rf "${tmp:?}/$tag" && mkdir -p "$tmp/$tag/bin" || { bad "$name — could not stage"; return; }
  sed "$mutation" "$root/bin/verdicts.sh" > "$tmp/$tag/bin/verdicts.sh" \
    || { bad "$name — sed failed, so this proves nothing"; return; }
  [ -s "$tmp/$tag/bin/verdicts.sh" ] || { bad "$name — the mutant is empty"; return; }
  cmp -s "$tmp/$tag/bin/verdicts.sh" "$root/bin/verdicts.sh" \
    && { bad "$name — the break did not apply, so this proves nothing"; return; }
  caught "$tag" || { bad "$name — the suite passed against a broken chain"; return; }

  printf '  ok    %s\n' "$name"
}

# The whole point. A claimed prior round with no record must refuse, not answer.
wreck "a chain that answers without a prior verdict is caught" \
  openchain 's|^        note "round $round claims.*$|        return 0|'

# A verdict from another review is another chain's history. Accepting it lets a stale record from an
# older charter satisfy a round it never saw.
wreck "a chain that accepts any review's verdict is caught" \
  anyreview 's|grep -Fq -- "$review" "$file"|true|'

# Round 1 has no prior and must not be made to invent one; every later round must look.
wreck "a chain where no round ever looks back is caught" \
  neverlook 's#^    \[ "$want" -ge 1 \] .*$#    return 0#'

# Numbering is how a round knows which record is its prior.
wreck "a chain that always reports round 1 is caught" \
  stuckone 's|^    printf .%03d\\n. "$(( .*$|    printf "001\\n"|'

echo
[ "$failed" -eq 0 ] && echo "ALL GREEN" || echo "FAILURES ABOVE"
exit $failed
