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
# `plugins/floor/core.dirs` says what core is, and this reads it rather than keeping a copy. Every
# check that refuses a word in core reads that one file, so a directory added there moves them all.
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

# Floor's core, named from floor's own root. The file says which directories and why it ships with
# the plugin rather than living here; this prefixes each with the directory the file sits in.
readonly CORE_DIRS=plugins/floor/core.dirs

say()  { printf '%s\n' "$1"; }
fail() { printf 'hosts: %s\n' "$1" >&2; exit 3; }

main() {
    [ "$#" -eq 0 ] || fail 'takes no arguments'

    # Missing and saying nothing are one answer here: either way this gate has no core to read.
    CORE=$(grep '^[^#]' "$CORE_DIRS" 2>/dev/null | sed "s|^|${CORE_DIRS%/*}/|")
    [ -n "$CORE" ] || fail "$CORE_DIRS is missing, or names no directory"

    absent=$(core_that_is_not_here)
    [ -z "$absent" ] || fail "$CORE_DIRS names a directory that is not here: ${absent% }"

    caught=$(host_words_in_code)

    [ -z "$caught" ] || refuse "$caught"

    say "hosts   core names no host"
}

# Named rather than counted. The old message listed all three whatever was absent, so a gate that
# could not read one directory said nothing about which.
core_that_is_not_here() {
    for dir in $CORE; do
        [ -d "$dir" ] || printf '%s ' "$dir"
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
