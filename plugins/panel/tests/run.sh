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

bash "$root/tests/chain.sh" || failed=1
echo

echo "audit — break the chain, the suite must notice"

caught() { red_against chain.sh RUNNER="$tmp/$1/bin/verdicts.sh"; }

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
  caught "$tag"
  case $? in
    1) bad  "$name — the suite passed against a broken chain"; return ;;
    2) moot "$name — the mutant never answered, so this proves nothing"; return ;;
  esac

  printf '  ok    %s\n' "$name"
}

# The whole point. A claimed prior round with no record must refuse, not answer.
wreck "a chain that answers without a prior verdict is caught" \
  openchain 's|^        note "round $round claims.*$|        return 0|'

# A verdict from another review is another chain's history. Accepting it lets a stale record from an
# older charter satisfy a round it never saw.
wreck "a chain that accepts any review's verdict is caught" \
  anyreview 's|grep -Fq -- "$review" "$file"|true|'

# A round that is not a round reached the exemption round 1 has. Exit 2 is *asked for something this
# does not do*; 1 is *a prior was claimed and nothing records it*. Different remedies.
wreck "a round that is not a round answered as round one is caught" \
  anyround 's|^    refuse_unless_a_round "$round"$|    :|'

# Round 1 has no prior and must not be made to invent one; every later round must look.
wreck "a chain where no round ever looks back is caught" \
  neverlook 's#^    \[ "$want" -ge 1 \] .*$#    return 0#'

# Numbering is how a round knows which record is its prior.
wreck "a chain that always reports round 1 is caught" \
  stuckone 's|^    printf .%03d\\n. "$(( .*$|    printf "001\\n"|'

# A new chain and a mistyped path are the same directory to `next`, and `001` is the round `prior`
# exempts. It cannot tell them apart; staying quiet about which it chose is what let it matter.
wreck "a new chain that says nothing is caught" \
  quietstart 's|note "no rounds at |: "|'

# The stamp is the whole reason `prior` can tell one chain from another. A recorder that omits it
# writes verdicts that fail the next honest round.
wreck "a recorder that does not stamp the review is caught" \
  nostamp 's|^        printf .Judged: %s\\n\\n. "$review"$|        :|'

# Two rounds writing the same file is one round overwritten.
wreck "a recorder that always writes round 1 is caught" \
  sameslot 's|^    round=$(next_round "$dir")$|    round=001|'


# The tally every check reports through. A break that empties a
# suite used to turn it green, and no audit could see it,
# because the audit reads the same exit code.
( . "$root/tests/lib.sh"; summary 'a suite that ran nothing' ) >/dev/null 2>&1 \
  && bad "a suite that ran nothing passed" \
  || printf '  ok    a suite that ran nothing does not pass\n'
echo
# End to end, and not just the bound. A runner that never returns
# must reach the verdict rather than the answer
# the suite would have given without it.
mkdir -p "$tmp/hang/bin" && printf '#!/bin/sh\nsleep 30\n' > "$tmp/hang/bin/verdicts.sh"
( deadline=1; caught hang )
[ "$?" -eq 2 ] && printf '  ok    a hanging mutant reaches the verdict, not a pass\n' \
               || bad "a hanging mutant did not reach the verdict"

# The bound itself, because no mutant has ever hung
# and an unused guard is the one
# that rots.
( deadline=1; bounded "$deadline" sleep 5 )
[ "$?" -eq 2 ] && printf '  ok    a mutant that never answers is bounded\n' \
               || bad "a mutant that never answers was not bounded"

[ "$failed" -eq 0 ] && echo "ALL GREEN"
[ "$failed" -eq 1 ] && echo "FAILURES ABOVE"
[ "$failed" -eq 3 ] && echo "PROVED NOTHING — the experiments above never ran"
exit $failed
