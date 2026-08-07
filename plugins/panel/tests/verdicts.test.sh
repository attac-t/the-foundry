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

it() {
  local behaviour="$1" want="$2" panel="$3" got
  bash "$VERDICTS" "$panel" >/dev/null 2>&1
  got=$?
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1)); printf '  ok    %s\n' "$behaviour"
    return 0
  fi
  fail=$((fail + 1)); printf '  FAIL  %s — wanted %s, got %s\n' "$behaviour" "$want" "$got"
}

echo "verdicts.sh"
echo

it "accepts an approval whose judges all filed"     0 "$PANELS/complete"
it "accepts a run still in flight"                  0 "$PANELS/in-progress"
it "rejects an approval with an empty trail"        1 "$PANELS/empty-verdicts"
it "rejects a gate that filed nothing"              1 "$PANELS/partial"
it "rejects an approval anchored to no commit"      1 "$PANELS/no-commit"
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
