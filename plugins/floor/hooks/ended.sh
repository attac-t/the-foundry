#!/bin/sh
# SessionEnd: record that a session holding this run ended, and how far the run had got.
#
# **The only line floor writes that nobody typed.** Measured 19 September: 76
# runs of 183 held more than `run.began`, and a worker typed each of them.
# A count that rises when somebody chooses to type more proves nothing.
#
# **`SessionEnd`, never `Stop`.** Stop fires at the end of every turn and would
# fill a run with repeats. This fires once, when the session ends.
#
# **A line proves a clean end. A missing one proves nothing.** A killed session
# never reaches this hook, so a run with no line may still be at work.
#
# Exit 0 always. A hook that refused would hold a session open over a record
# nobody asked for, and the record is worth less than the session.

root="$(cd "$(dirname "$0")/.." && pwd)"

# No run, no line, and nothing said. A session holding none has nothing to record.
dir=$(sh "$root/bin/run.sh" path 2>/dev/null) || exit 0

# The public verb: `how_far` is the runner's, and a hook is another process.
stage=$(sh "$root/bin/run.sh" runs 2>/dev/null |
        awk -F'\t' -v id="${dir##*/}" '$2 == id { print $1; exit }')

[ -n "$stage" ] || stage=unknown

sh "$root/bin/run.sh" observe session.ended stage="$stage" >/dev/null 2>&1

exit 0
