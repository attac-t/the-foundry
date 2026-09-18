#!/bin/sh
#
# Fails when the doctrine's durable kinds and `.foundry/durable.txt` have parted.
#
# The doctrine names what survives replacing the machinery. **A list nobody reads is the fault this
# answers**, and a list nothing checks becomes one within a revision or two.
#
# Three readings, and they are three:
#
#   reading           what it compares
#   the same kinds    doctrine and registry name one set, in one order
#   the same half     a kind the doctrine calls machinery is machinery here too
#   a real writer     every machinery kind names a function that exists in floor's runner
#
# **It cannot reach meaning, and says so.** That two installations agree on what a receipt *means*
# is beyond any check here — #725 records that, and the doctrine says it on its own face.
#
# **A people-written kind names no function, and that is the answer rather than a gap.** A goal, a
# doctrine and a clause are written by people. Demanding a writer for one would invent machinery the
# doctrine refuses.
#
#   sh bin/durable.sh          grade
#   sh bin/durable.sh audit    break it four ways, require each to answer
#
# Exit: 0 they agree, 1 they have parted, 3 a file could not be read

set -u

readonly DOCTRINE=.foundry/doctrine.md
readonly REGISTRY=.foundry/durable.txt
readonly RUNNER=plugins/floor/bin/run.sh

failed=0

say()  { printf '%s\n' "$*"; }
bad()  { printf '  FAIL  %s\n' "$*"; failed=1; }

main() {
    cd "$(dirname "$0")/.." || exit 3

    [ "${1:-check}" = audit ] && { bash tests/durable.sh; exit $?; }

    readable "$DOCTRINE" && readable "$REGISTRY" && readable "$RUNNER" || exit 3

    refuse_a_set_that_parted
    refuse_a_half_that_moved
    refuse_a_writer_that_is_not_there

    verdict
}

readable() {
    [ -r "$1" ] && return 0

    say "FAIL — [$1] could not be read, so nothing was compared."
    return 1
}

# --- what each file says ---

#
# The kinds the doctrine names, in the order it names them.
#
# `a **<kind>** | <half> |` is the row shape. Read off the page rather than kept here, because a
# second copy is the drift this file exists to catch.
doctrine_kinds() {
    sed -n 's/^| a \*\*\([^*]*\)\*\* *| *\([a-z]*\) *|.*/\1\t\2/p' "$DOCTRINE"
}

#
# The registry, without its header.
#
# **Two or more spaces separate the columns, because a kind may hold one.** `ledger row` is two
# words, and a single-space split reads it as a kind called `ledger` sitting in a half called `row`.
registry_kinds() {
    awk -F'  +' '!/^#/ && NF >= 3 { print $1 "\t" $2 }' "$REGISTRY"
}

# The writer each machinery kind names.
registry_writers() {
    awk -F'  +' '!/^#/ && NF >= 3 && $2 == "machinery" { print $1 "\t" $3 }' "$REGISTRY"
}

# --- the three readings ---

#
# One set, in one order.
#
# **Order, because a reader meets them in it.** A kind moved between the two files reads as two
# different lists to anyone comparing them by eye, which is how a list stops being read at all.
refuse_a_set_that_parted() {
    said=$(doctrine_kinds | cut -f1)
    held=$(registry_kinds | cut -f1)

    [ "$said" = "$held" ] && { say '  ok    the doctrine and the registry name one set, in one order'; return; }

    bad 'the doctrine and the registry name different sets'
    printf '        doctrine: %s\n' "$(printf '%s' "$said" | tr '\n' ' ')"
    printf '        registry: %s\n' "$(printf '%s' "$held" | tr '\n' ' ')"
}

# Which half each kind sits in. A kind that moved from people to machinery is a design change, and a
# design change that only one file knows about is the drift.
refuse_a_half_that_moved() {
    said=$(doctrine_kinds)
    held=$(registry_kinds)

    [ "$said" = "$held" ] && { say '  ok    every kind sits in the same half in both'; return; }

    bad 'a kind sits in one half in the doctrine and the other in the registry'
}

#
# A writer that is there.
#
# **The whole of what a check can reach.** It proves floor still holds the function the registry
# names, and nothing about what the bytes mean.
refuse_a_writer_that_is_not_there() {
    missing=$(registry_writers | while IFS="$(printf '\t')" read -r kind writer; do
        grep -q "^$writer()" "$RUNNER" && continue
        printf '%s\t%s\n' "$kind" "$writer"
    done)

    [ -z "$missing" ] && { say '  ok    every machinery kind names a writer the runner still holds'; return; }

    bad 'a machinery kind names a writer the runner does not hold'
    printf '        %s\n' "$missing"
}

verdict() {
    [ "$failed" -eq 0 ] || { say 'FAIL — the doctrine and the registry have parted.'; exit 1; }

    say "PASS — $(doctrine_kinds | grep -c .) durable kinds, and the two files agree."
    say '       Meaning is not read. A green here says nothing about what two installations mean.'
}

main "$@"
