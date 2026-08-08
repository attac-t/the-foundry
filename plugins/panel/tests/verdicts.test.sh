#!/usr/bin/env bash
#
# The oracle for bin/verdicts.sh. One row per behaviour, each naming the status it wants and the
# refusal it means. A status says something went wrong, never which thing, and three consecutive
# review rounds turned on that distinction.
#
# Usage: bash plugins/panel/tests/verdicts.test.sh
# Exit   0 every assertion held · 1 one did not, or none ran

set -uo pipefail

cd "$(dirname "$0")/../../.."
source plugins/panel/tests/harness.sh

readonly VERDICTS=plugins/panel/bin/verdicts.sh
readonly PANELS=plugins/panel/tests/panels

# it <behaviour> <wanted status> <panel directory> <expected reason>
it() {
  local behaviour=$1 wanted=$2 panel=$3 reason=$4

  if [ ! -d "$panel" ]; then
    refuse "$behaviour" "no fixture at $panel"
    return
  fi

  attempt bash "$VERDICTS" "$panel"
  judge "$behaviour" "$wanted" "$status" "$output" "$reason"
}

echo "verdicts.sh"
echo

it "accepts an approval whose judges all filed"     0 "$PANELS/complete"              "on record for"
it "accepts a run still in flight"                  0 "$PANELS/in-progress"           "owes no trail"
it "rejects an approval with an empty trail"        1 "$PANELS/empty-verdicts"        "no verdict beside it"
it "rejects a gate that filed nothing"              1 "$PANELS/partial"               "left no verdict"
it "rejects an approval anchored to no commit"      1 "$PANELS/no-commit"             "cites no commit"

# A closed run left in place discharges the next one for free — the defect this gate exists to
# catch, surviving inside it. Both halves: the approval, and the verdicts behind it.
it "rejects an approval naming another charter"     1 "$PANELS/foreign-approval"      "does not name this charter"
it "rejects a trail left over from an earlier run"  1 "$PANELS/stale-trail"           "no verdict beside it"

# The shape the charter was written against: a flat pre-moments roster, an approval claiming four
# rounds, cold-read-log.md surviving because appending a row is cheaper than creating a file, and
# not one verdict. It lived in another repository until that repository moved.
it "rejects the shape this charter was written for" 1 "$PANELS/flat-roster"           "seats no judge"

# In flight outranks the empty roster: a charter with no approval owes nothing, whatever its
# `## Panel` looks like. Swap the two branches and only this row turns red.
it "lets a rosterless charter run before approval"  0 "$PANELS/flat-roster-in-flight" "owes no trail"

# `defaced` is seven characters of valid hex. Without the digit lookahead it reads as a commit.
it "rejects prose that merely looks like a commit"  1 "$PANELS/defaced"               "cites no commit"

# Usage is a third outcome, not a flavour of failure.
it "refuses two seats sharing one role name"        2 "$PANELS/stem-collision"        "share a role name"
it "refuses a directory holding no charter"         2 "$PANELS/no-charter"            "no charter at"

summary "an approval here cannot outrun its evidence."
