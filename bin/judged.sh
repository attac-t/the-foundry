#!/bin/sh
#
# Fails when `.foundry/judged` pins an adapter this tree does not ship at that content.
#
# **The pin is this repository's trust decision and nothing checked it.** Floor fails closed at 40
# when the two drift, so the fault is caught — by whoever next runs a judge, on a run that then
# stops. That is late. Editing the adapter and forgetting the digest is one commit away at all
# times, and an exit code costs nothing.
#
# **Not floor's.** Floor reads a repository's declaration and never this one's. This is the
# repository grading its own declaration, so it lives beside the other gates that do that.
#
# POSIX plus `git`. `git hash-object --no-filters` is exactly what floor computes, and computing it
# a second way here would be a second answer to compare against rather than the same one.
#
# A declaration naming no shipped adapter fails. **This repository judges itself through one**, so
# nothing to check is a change, not a clean sheet — and a gate that passes over an empty set
# certifies nothing.
#
# No `set -e`: every reach is read, and one bad pin must not hide the next.
#
# Exit: 0 every pin names what is here, 1 one does not, 3 the declaration could not be read

set -u

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root" || exit 3

readonly DECLARED=.foundry/judged
readonly ADAPTERS=plugins/floor/adapters

checked=0
failed=0

main() {
    ensure_the_declaration_reads

    while_reading_each "$(reaches)"
    verdict
}

ensure_the_declaration_reads() {
    [ -r "$DECLARED" ] && return 0

    printf 'FAIL — %s is not there, or cannot be read. This gate read nothing.\n' "$DECLARED"
    exit 3
}

# Every `@adapter` reach, as `id pin`. A reach of any other shape names no shipped adapter and is
# the repository's own business.
reaches() {
    awk '!/^[ \t]*#/ && $1 == "reach" && $3 == "@adapter" { print $4, $5 }' "$DECLARED"
}

#
# A here-doc, not a pipe. Both tallies are raised inside this loop, and a tally raised in a pipe's
# subshell dies with it — the failure `bin/gates.sh` and floor's own runner each paid for once.
#
while_reading_each() {
    while read -r adapter pin; do
        [ -n "$adapter" ] || continue

        checked=$((checked + 1))
        grade "$adapter" "$pin"
    done <<EOF
$1
EOF
}

grade() {
    at=$ADAPTERS/$1/run.sh

    [ -f "$at" ] || { report "$1" "no adapter at $at"; return; }

    here=$(git hash-object --no-filters -- "$at" 2>/dev/null)
    [ "$here" = "$2" ] && { printf '  ok    %s is pinned at what this tree ships\n' "$1"; return; }

    report "$1" "pinned at [$2] and this tree ships [${here:-nothing readable}]"
}

report() {
    printf '  FAIL  %s — %s\n' "$1" "$2"
    printf '        take the digest with: git hash-object --no-filters -- %s\n' "$ADAPTERS/$1/run.sh"
    failed=$((failed + 1))
}

#
# A green gate over nothing is the failure this names rather than repeats.
#
verdict() {
    [ "$checked" -eq 0 ] && {
        printf 'FAIL — %s names no @adapter reach, so this gate graded nothing.\n' "$DECLARED"
        return 1
    }

    [ "$failed" -eq 0 ] && {
        printf 'PASS — %d pinned adapter(s), each the content this tree ships.\n' "$checked"
        return 0
    }

    printf 'FAIL — %d of %d pins name content this tree does not ship.\n' "$failed" "$checked"
    return 1
}

main "$@"
