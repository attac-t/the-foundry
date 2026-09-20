#!/bin/sh
# SessionStart: say when work on this host stopped moving, so nobody has to ask.
#
# **#574 wants stranded work noticed without a person asking.** `settled` has answered it for a
# fortnight and a person has to type it. Three runs here had been quiet for twelve days, and no
# session was ever told.
#
# **Silent unless something is quiet.** `drift.sh` names what a hook that speaks daily about
# nothing costs, and this one on a moving host would be exactly that.
#
# **The count, never the list.** Which runs, and whether any should be picked up, is what `settled`
# prints. A hook that listed seven would be the report, and the report is already a command.
#
# **A timeout here is silence, and silence is its other state.** The walk behind `settled` measured
# 2.3 seconds on a home of 195 runs, against a ten second budget. Nothing breaks if it loses.

root="$(cd "$(dirname "$0")/.." && pwd)"

main() {
    quiet=$(runs_that_stopped) || exit 0
    [ "$quiet" -gt 0 ] || exit 0

    printf '🔨 floor: %s stopped moving. `run.sh settled` says which.\n' "$(spelt "$quiet")"
}

# Reading `settled`'s own rows keeps one definition of quiet in the plugin. A second `find` here
# would be a copy of the bar, and two copies drift.
runs_that_stopped() {
    sh "$root/bin/run.sh" settled 2>&1 | grep -c 'nothing touched'
}

spelt() {
    [ "$1" -eq 1 ] && { printf 'one run here has'; return 0; }

    printf '%s runs here have' "$1"
}

main "$@"
