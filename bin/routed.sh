#!/bin/sh
#
# Fails when `deliver` can leave with a code no arm of `deliver_and_route` routes and floor's README
# does not name as let go. #1159.
#
# `deliver_and_route` sends four groups of codes somewhere and lets every other code go. Nothing
# listed which codes reach that line, so a new one fell there unseen: 57 once, and 6 since #1160.
#
# **The codes are read from the runner, never from a page.** `bin/routed.awk` follows every call
# from `deliver` and reads each exit where it sits. It errs wide: a code it adds is noise to list,
# and a code it drops would be a run let go unseen.
#
# **Two lines of the README are read, each marked at its end.** The let-go line names each code
# let go. The wait line names exactly the codes the wait arm routes. Every other place points at them.
#
# **A missing anchor is refused, never read as empty.** No `deliver`, no `deliver_and_route` case, or
# no marked line exits 3 and says which, since nothing can be held to what is not there.
#
# POSIX `sh` and `awk`. `audit` also needs `bash`, because the suite is bash like every suite here.
#
# Usage: sh bin/routed.sh
#        sh bin/routed.sh audit   drive tests/routed.sh first, then the check
#
# A case names the runner and the page, so it drives a fixture and never this tree:
#   FOUNDRY_ROUTED_RUNNER and FOUNDRY_ROUTED_PAGE, by default floor's run.sh and README.md
#
# Exit: 0 every code is routed or named, 1 one is not, or the wait line and arm differ,
#       3 an anchor is missing, so nothing could be held to it
set -u

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root" || exit 3

RUNNER=${FOUNDRY_ROUTED_RUNNER:-plugins/floor/bin/run.sh}
PAGE=${FOUNDRY_ROUTED_PAGE:-plugins/floor/README.md}
LET_GO='<!-- routed: let go -->'
WAITS='<!-- routed: wait -->'

main() {
    [ "${1:-}" = audit ] && prove_it_can_go_red

    ensure_the_anchors
    left=$(awk -v start=deliver -f "$root/bin/routed.awk" "$RUNNER" "$RUNNER")
    routed=$(codes_the_arms_route)
    named=$(codes_on_the_line "$LET_GO")

    unsent=$(each_code_unsent)
    twice=$(each_code_routed_and_named)
    unresolved=$(printf '%s\n' "$left" | awk -F'\t' '$1 == "?" { print "  `" $2 "` exits through a value nothing could read" }')
    waiting=$(waits_that_differ)
    verdict
}

ensure_the_anchors() {
    [ -r "$RUNNER" ] || refuse "the runner [$RUNNER] could not be read"
    [ -r "$PAGE" ]   || refuse "the page [$PAGE] could not be read"
    grep -q '^deliver() *[{(]' "$RUNNER"         || refuse 'the runner defines no `deliver`, so no code can be followed from it'
    [ -n "$(codes_the_arms_route)" ]              || refuse '`deliver_and_route` holds no arm, so nothing can be held to one'
    grep -qF "$LET_GO" "$PAGE"                    || refuse "the page marks no let-go line [$LET_GO]"
    grep -qF "$WAITS" "$PAGE"                     || refuse "the page marks no wait line [$WAITS]"
}

refuse() { printf 'FAIL — %s.\n' "$1"; exit 3; }

# Each code an arm's pattern names, one a line. With `wait`, only the arm that waits on a person.
codes_the_arms_route() {
    awk -v only="${1:-}" '
        /^deliver_and_route\(\)/ { inside = 1; next }
        inside && /^}/ { exit }
        inside && /^[ \t]+[0-9|]+\)/ {
            if (only == "wait" && $0 !~ /wait_on_a_person/) next
            arm = $1; sub(/\).*/, "", arm); n = split(arm, code, "|")
            for (i = 1; i <= n; i++) print code[i]
        }' "$RUNNER" | sort -un
}

# The codes on a marked line, its marker and any `exit` name dropped.
codes_on_the_line() {
    grep -F "$1" "$PAGE" | head -1 | sed 's/<!--.*-->//' | tr -c '0-9' '\n' | grep . | sort -un
}

# One line a code `deliver` can leave with that no arm routes and the let-go line does not name.
each_code_unsent() {
    printf '%s\n' "$left" | awk -F'\t' -v routed=" $(spaced "$routed") " -v named=" $(spaced "$named") " '
        $1 == "?" || $1 == "" { next }
        index(routed, " " $1 " ") || index(named, " " $1 " ") { next }
        !said[$1]++ { printf "  %s, from `%s`\n", $1, $2 }'
}

# A code an arm routes is not let go, so the line naming it as let go says what is false.
each_code_routed_and_named() {
    for code in $named; do
        printf '%s\n' "$routed" | grep -qx "$code" || continue
        printf '  %s is routed by an arm, and the let-go line names it too\n' "$code"
    done
}

spaced() { printf '%s' "$1" | tr '\n' ' '; }

# The wait line must name what the wait arm routes, no more and no fewer.
waits_that_differ() {
    arm=$(spaced "$(codes_the_arms_route wait)")
    line=$(spaced "$(codes_on_the_line "$WAITS")")
    [ "$arm" = "$line" ] && return 0
    printf '  the wait arm routes [%s] and the wait line names [%s]\n' "${arm% }" "${line% }"
}

verdict() {
    [ -z "$unsent$twice$unresolved$waiting" ] && {
        printf 'PASS — every code deliver can leave with is routed or let go by name: %s\n' "$(spaced "$named")"
        exit 0
    }

    printf 'FAIL — deliver can leave with a code nothing routes and the README does not name:\n'
    printf '%s\n' "$unsent" "$twice" "$unresolved" "$waiting" | grep .
    exit 1
}

# A gate that has only ever been green proves nothing about what it would catch. The suite plants
# each fault in a fixture and reads this script's exit and words.
prove_it_can_go_red() {
    command -v bash >/dev/null 2>&1 || {
        printf 'FAIL — bash is not on this host, so the suite did not run.\n'
        exit 3
    }
    bash "$root/tests/routed.sh" || exit 1
    printf '\n'
}

main "$@"
