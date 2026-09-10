#!/bin/sh
#
# Drives every hook this repository ships against the calls it has to judge.
#
# **A hook is the only wall a caller meets before the write.** Forty-three checks shipped before
# anything drove the seam, and its most fragile line broke twice — silently, because a tool rewrote
# a backslash on the way through.
#
# Each suite writes its calls to disk rather than typing them. A tool call on a suite's own command
# line would be read by the live hooks running that suite.
#
# **This grades the hooks, never the rules they carry.** `comments.sh audit` grades the rendering
# and `identity.md` states what an author owes; both stand whether or not a hook is installed.
#
# Usage: sh bin/hooks.sh
#
# Exit: 0 every hook answers as it must, 1 one did not, 3 a suite is not here to run
#
set -u

cd "$(dirname "$0")/.." || exit 3

SUITES='identity seam'

say()  { printf '%s\n' "$1"; }
fail() { printf 'hooks: %s\n' "$1" >&2; exit 3; }

main() {
    [ "$#" -eq 0 ] || fail 'takes no arguments'

    failed=0

    for suite in $SUITES; do
        run_one "$suite" || failed=$((failed + 1))
    done

    [ "$failed" -eq 0 ] || refuse "$failed"

    say "hooks    every hook answered as it must"
}

# A suite that is not there proves nothing, and a loop that skips it says nothing either. That is
# the shape `gates.sh` calls exit 3: the gate did not answer.
run_one() {
    [ -f "tests/$1.sh" ] || fail "tests/$1.sh is not here, so this gate read nothing"

    bash "tests/$1.sh"
}

refuse() {
    say ""
    say "hooks    $1 of $(printf '%s\n' $SUITES | grep -c .) hook suites went red."
    exit 1
}

main "$@"
