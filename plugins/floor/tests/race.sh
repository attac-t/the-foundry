#!/bin/bash
#
# Race two hosts for one item and count the winners.
#
#   bash plugins/floor/tests/race.sh          a thousand rounds
#   bash plugins/floor/tests/race.sh 50       fewer, while you are changing one
#
# **`run.sh` does not name this, and that is the point.** Two processes a round starve this machine,
# and the suite says so beside the claim it tests. #303 wants the proof anyway, so it is driven here
# and read by hand — the shape `bin/breaks.sh` uses for a check too expensive to gate.
#
# **Two hosts, not two machines.** The adapter takes the host as an argument, so a name is the whole
# of what a second host is. `run.sh claim` reads `uname -n` and nothing overrides it, which is why
# this drives the adapter and not the command.
#
# What one round proves:
#
#   exactly one of the two exits 0, and the other exits 4
#   the stamp names the one that won, and nothing else
#   and no draft survives the round that wrote them
#
# **The third is not decoration.** `mkdir` was the swap once, and a host dying between the directory
# and the stamp left a claim nobody could take, break or release. A draft surviving a race is that
# same fault arriving by a different road.
#
# Exit: 0 every round left one winner, 1 a round did not, 3 it could not set up

set -u

root=$(cd "$(dirname "$0")/../../.." && pwd)
adapter=$root/plugins/floor/lib/source-dir.sh

won=0
lost=0

main() {
    rounds=${1:-1000}

    ensure_the_adapter_is_here
    make_a_source

    race_every_round "$rounds"

    report
}

ensure_the_adapter_is_here() {
    [ -f "$adapter" ] && return 0

    fail "no directory adapter at $adapter"
}

# Its own source and its own home, so a race here never touches the one a person keeps.
make_a_source() {
    tmp=${TMPDIR:-/tmp}/race-$$
    src=$tmp/source

    mkdir -p "$src/items" || fail "could not make a source under $tmp"
    trap 'rm -rf "$tmp"' EXIT

    export FOUNDRY_SOURCE_DIR=$src
}

race_every_round() {
    n=0
    while [ "$n" -lt "$1" ]; do
        n=$((n + 1))
        printf 'Race for it\n' > "$src/items/$n"

        one_round "$n"

        [ $((n % 50)) -eq 0 ] && printf '  %s rounds, %s won, %s lost\n' "$n" "$won" "$lost"
    done
}

#
# Both start before either is waited on. Starting one, reading it, then starting the other is a
# sequence wearing a race's clothes, and it would pass against a claim with no exclusion at all.
one_round() {
    claim_in_the_background alpha "$1" "$tmp/a"
    claim_in_the_background beta  "$1" "$tmp/b"
    wait

    judge "$1" "$(cat "$tmp/a")" "$(cat "$tmp/b")"
}

claim_in_the_background() {
    ( sh "$adapter" claim "$2" "$1" >/dev/null 2>&1; printf '%s' "$?" > "$3" ) &
}

# Four is the adapter refusing a host that does not hold it. Any other pair is the failure this
# exists to find, including two zeroes.
winner_of() {
    [ "$1" = 0 ] && [ "$2" = 4 ] && { printf alpha; return 0; }
    [ "$1" = 4 ] && [ "$2" = 0 ] && { printf beta;  return 0; }

    return 1
}

judge() {
    winner=$(winner_of "$2" "$3") || { note "$1" "alpha said $2 and beta said $3"; return; }

    stamped=$(sh "$adapter" held "$1" | awk -F'\t' '{ print $2 }')
    [ "$stamped" = "$winner" ] || { note "$1" "$winner won and the stamp says '$stamped'"; return; }

    left=$(ls "$src/claims/$1" 2>/dev/null | grep -v '^held$')
    [ -z "$left" ] || { note "$1" "a draft outlived the race: $left"; return; }

    won=$((won + 1))
}

note() { lost=$((lost + 1)); printf '  FAIL  round %s — %s\n' "$1" "$2"; }
say()  { printf '%s\n' "$1"; }
fail() { printf 'race: %s\n' "$1" >&2; exit 3; }

report() {
    say ""
    say "$won rounds left one winner, $lost did not"

    [ "$lost" -eq 0 ]
}

main "$@"
