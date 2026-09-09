#!/bin/sh
#
# Fails when floor's core names a host.
#
# `run.sh` states the boundary twice, in its own comments — *it claims nothing about container, VM
# or sandbox adapters*, and *a container or a sandbox would have to be git to put its workspace
# where core looks*. Until this, nothing read either sentence.
#
# #299 is the work that would break it. A machine becomes a Foundry host from Docker, and the
# convenient line to write is a test for a container file, inside `run.sh`.
#
# **A comment may name a host. Code may not.** Those two sentences are the fixture: a check that
# reads them as violations gates the opposite of what is wanted.
#
# Core is what floor ships and runs — `bin`, `lib` and `hooks`. Not `tests`, which stands hosts up
# on purpose, and not the other plugins, which have no such boundary to keep.
#
# Usage: sh bin/hosts.sh
#
# Exit: 0 core names no host, 1 a host word is in code, 3 the gate could not read
#
set -u

cd "$(dirname "$0")/.." || exit 3

# Six words, and every one of them is a host or a way of being one. Nothing shorter went in: a
# forbidden name that is a substring of an ordinary word turns a gate into a false red, and this
# repository has already spent a day on one.
HOSTS='docker|container|podman|kubernetes|lxc|chroot'

CORE='plugins/floor/bin plugins/floor/lib plugins/floor/hooks'

say()  { printf '%s\n' "$1"; }
fail() { printf 'hosts: %s\n' "$1" >&2; exit 3; }

main() {
    [ "$#" -eq 0 ] || fail 'takes no arguments'

    core_is_here || fail 'floor ships no bin, lib or hooks here'

    caught=$(host_words_in_code)

    [ -z "$caught" ] || refuse "$caught"

    say "hosts   core names no host"
}

core_is_here() {
    for dir in $CORE; do
        [ -d "$dir" ] || return 1
    done
}

host_words_in_code() {
    for dir in $CORE; do
        for file in "$dir"/*.sh; do
            [ -f "$file" ] || continue
            name_the_lines "$file"
        done
    done
}

# A line whose first character is a hash is prose, and prose may name a host — the two sentences in
# `run.sh` stating this very boundary are what that allowance is for.
#
# A comment after code is not separated out. One naming a host is caught, and that is the safer
# direction of the two: a loud false red costs an edit, and a boundary nothing holds costs the
# thing it was keeping.
name_the_lines() {
    awk -v file="$1" -v hosts="$HOSTS" '
        { bare = $0; sub(/^[[:space:]]+/, "", bare) }

        bare ~ /^#/          { next }
        tolower(bare) ~ hosts { printf "        %s:%d  %s\n", file, NR, bare }
    ' "$1"
}

# Every line, never the first. A file with three is three edits, and a gate naming one sends the
# reader back twice for what it already knew.
refuse() {
    say "$1"
    say "hosts   a host word is in code. A comment may name one; code may not."
    exit 1
}

main "$@"
