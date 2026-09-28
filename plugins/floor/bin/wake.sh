#!/bin/sh
#
# A trigger for a host with no timer of its own: `run.sh pass`, a wait, and again.
#
# **It keeps nothing and holds no lock.** One live pass per host is `run.sh pass`'s own, taken at its
# door, so two of these on one host cost a wake, never a second pass. cron, a systemd timer or a
# container loop need nothing from here, and each is as good a trigger.
#
#   sh plugins/floor/bin/wake.sh <seconds>
#
# Before each pass it looks for `wake.stop` in floor's home, and once that file exists it stops.
#
# Exit: 0 asked to stop. 2 no cadence, or one past the claim window. 3 no checkout it can write, or
#       no floor home.
#
# `set -e` is off: a pass's exit is that pass's own record, and never a reason to stop waking.
set -u

readonly RUNNER="$(dirname "$0")/run.sh"

main() {
    read_the_cadence "$@"
    refuse_a_cadence_past_the_claim_window
    refuse_a_checkout_it_cannot_write
    locate_the_home

    name_this_wake
    wake_until_asked_to_stop
}

note() { printf 'wake: %s\n' "$*" >&2; }

read_the_cadence() {
    [ "$#" -eq 1 ] || { note "usage: wake.sh <seconds> — the host names the cadence, and there is no default"; exit 2; }
    is_whole_seconds "$1" || { note "a cadence is whole seconds, one or more, with no leading zero: [$1]"; exit 2; }

    cadence=$1
}

is_whole_seconds() {
    case $1 in ''|0*|*[!0-9]*) return 1 ;; esac
}

#
# **Read the way `run.sh` reads it**, so the two never disagree about the window. A wake slower than
# the window lets a claim lapse between two passes, and another host takes the item mid-work.
refuse_a_cadence_past_the_claim_window() {
    window=${FOUNDRY_CLAIM_TTL:-3600}
    is_whole_seconds "$window" || { note "FOUNDRY_CLAIM_TTL is [$window], not whole seconds"; exit 2; }
    [ "$cadence" -le "$window" ] && return 0

    note "a cadence of $cadence seconds is past the claim window of $window, so a claim would lapse between passes"
    exit 2
}

#
# **Never floor's read-only `/src`.** A pass writes its run's pointer into the checkout it runs in, so
# a wake there fails every pass the same way. Clone it somewhere writable and wake that clone.
refuse_a_checkout_it_cannot_write() {
    top=$(git rev-parse --show-toplevel 2>/dev/null) || { note "a wake runs in a git checkout, and this is not one"; exit 3; }
    [ -w "$top" ] && return 0

    note "a wake runs in a checkout it can write, and this one is read-only — clone it somewhere writable"
    exit 3
}

locate_the_home() {
    home=$(sh "$RUNNER" home 2>/dev/null) && [ -n "$home" ] && return 0

    note "floor could not say where its home is"
    exit 3
}

# The four fields only the trigger knows, one token each. The pass records them, then unsets them.
name_this_wake() {
    FOUNDRY_WAKE="mechanism=wake.sh cadence=$cadence identity=$$ stops=wake.stop"
    export FOUNDRY_WAKE
}

wake_until_asked_to_stop() {
    until asked_to_stop; do
        sh "$RUNNER" pass </dev/null
        sleep "$cadence"
    done

    note "wake.stop is in floor's home, so this wake stops"
}

asked_to_stop() { [ -e "$home/wake.stop" ]; }

main "$@"
