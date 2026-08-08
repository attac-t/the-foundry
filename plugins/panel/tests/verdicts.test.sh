#!/usr/bin/env bash
#
# The oracle for bin/verdicts.sh. One row per behaviour, each asserting an exact exit code.
#
# Usage: bash plugins/panel/tests/verdicts.test.sh
# Exit   0 every assertion held · 1 one did not, or none ran

set -uo pipefail

cd "$(dirname "$0")/../../.."

readonly VERDICTS=plugins/panel/bin/verdicts.sh
readonly PANELS=plugins/panel/tests/panels

pass=0 fail=0

# A code alone cannot tell one refusal from another, and three verdicts in a row turned on exactly
# that. Rows that care pass a fragment of the expected message; the code must match *and* the
# reason must be the one claimed.
it() {
  local behaviour="$1" want="$2" panel="$3" because="${4:-}" got out
  if [ ! -d "$panel" ]; then
    fail=$((fail + 1)); printf '  FAIL  %s — no fixture at %s\n' "$behaviour" "$panel"
    return 0
  fi
  out=$(bash "$VERDICTS" "$panel" 2>&1)
  got=$?
  if [ "$got" != "$want" ]; then
    fail=$((fail + 1)); printf '  FAIL  %s — wanted %s, got %s\n' "$behaviour" "$want" "$got"
    return 0
  fi
  if [ -n "$because" ] && ! printf '%s' "$out" | grep -qF "$because"; then
    fail=$((fail + 1)); printf '  FAIL  %s — exit %s for the wrong reason; wanted "%s"\n' \
      "$behaviour" "$got" "$because"
    return 0
  fi
  pass=$((pass + 1)); printf '  ok    %s\n' "$behaviour"
}

echo "verdicts.sh"
echo

it "accepts an approval whose judges all filed"     0 "$PANELS/complete"
it "accepts a run still in flight"                  0 "$PANELS/in-progress"
it "rejects an approval with an empty trail"        1 "$PANELS/empty-verdicts" "no verdict beside it"
it "rejects a gate that filed nothing"              1 "$PANELS/partial" "left no verdict"
it "rejects an approval anchored to no commit"      1 "$PANELS/no-commit" "cites no commit"

# A closed run left in place discharges the next run for free — the defect this gate exists to
# catch, surviving inside it. Both halves: the approval, and the verdicts behind it.
it "rejects an approval naming another charter"     1 "$PANELS/foreign-approval" "does not name this charter"
it "rejects a trail left over from an earlier run"  1 "$PANELS/stale-trail" "no verdict beside it"

# The shape the charter was written against: a flat pre-moments roster, an approval claiming four
# rounds, cold-read-log.md surviving because a row is cheaper to append than a file is to create,
# and not one verdict. It lived in another repository until that repository moved; a corpus you do
# not own is a corpus that stops being evidence without telling you.
it "rejects the shape this charter was written for" 1 "$PANELS/flat-roster" "seats no judge"

# `defaced` is seven characters of valid hex. Without the digit lookahead it reads as a commit.
it "rejects prose that merely looks like a commit"  1 "$PANELS/defaced"

it "refuses two seats sharing one role name"        2 "$PANELS/stem-collision" "share a role name"
it "refuses a directory holding no charter"         2 "$PANELS/no-charter"

echo
total=$((pass + fail))

if [ "$total" -eq 0 ]; then
  echo "FAIL — no assertions ran. An empty suite is not a passing one."
  exit 1
fi

if [ "$fail" -gt 0 ]; then
  echo "FAIL — $fail of $total assertions did not hold."
  exit 1
fi

echo "PASS — $total assertions; an approval here cannot outrun its evidence."
