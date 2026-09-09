#!/bin/sh
#
# Fails when floor's core names a provider.
#
# Core holds the question and an adapter holds the provider. `join.sh` broke that once — a copy of
# `remote_is_github` lived there, which put a vendor's name in core — and its own suite has refused
# the two names in that one file ever since. **Nothing checks the rest**, so `run.sh`, `adopt.sh`,
# `say.sh` and both hooks carried the rule on discipline alone.
#
# **Two files may name one, and the reason differs for each.** `lib/source.sh` is the resolver, and
# choosing between adapters is the whole of its job. `lib/source-github.sh` is the adapter.
#
# **That exception list is why this is not `bin/hosts.sh`.** A host word is refused everywhere in
# core with nothing exempt. Folding the two together would grade two rules under one name.
#
# **A comment may name a provider**, for the same reason `hosts` allows it: the sentence explaining
# the seam contains the word the check forbids.
#
# Usage: sh bin/providers.sh
#
# Exit: 0 core names no provider, 1 a name is in code, 3 the gate could not read
#
set -u

cd "$(dirname "$0")/.." || exit 3

# Six vendors of a work source. Each is a whole word nothing else contains, because a forbidden name
# hiding inside an ordinary one has already cost this repository a day.
VENDORS='github|gitlab|bitbucket|jira|linear|gerrit'

CORE='plugins/floor/bin plugins/floor/lib plugins/floor/hooks'

ALLOWED='source.sh source-github.sh'

say()  { printf '%s\n' "$1"; }
fail() { printf 'providers: %s\n' "$1" >&2; exit 3; }

main() {
    [ "$#" -eq 0 ] || fail 'takes no arguments'

    core_is_here || fail 'floor ships no bin, lib or hooks here'

    caught=$(vendor_names_in_code)

    [ -z "$caught" ] || refuse "$caught"

    say "providers  core names no provider"
}

core_is_here() {
    for dir in $CORE; do
        [ -d "$dir" ] || return 1
    done
}

vendor_names_in_code() {
    for dir in $CORE; do
        for file in "$dir"/*.sh; do
            [ -f "$file" ] || continue
            may_name_one "$file" && continue

            name_the_lines "$file"
        done
    done
}

# The resolver and the adapter, by basename. A path would tie this to one layout, and the two files
# are what they are wherever floor puts them.
may_name_one() {
    for allowed in $ALLOWED; do
        [ "${1##*/}" = "$allowed" ] && return 0
    done

    return 1
}

# A line whose first character is a hash is prose. The sentences that explain the seam name the very
# vendor this refuses, and a check reading those as violations would gate the opposite.
name_the_lines() {
    awk -v file="$1" -v vendors="$VENDORS" '
        { bare = $0; sub(/^[[:space:]]+/, "", bare) }

        bare ~ /^#/             { next }
        tolower(bare) ~ vendors { printf "           %s:%d  %s\n", file, NR, bare }
    ' "$1"
}

# Every line, never the first. Three in a file is three edits, and a gate naming one sends the
# reader back twice for what it already knew.
refuse() {
    say "$1"
    say "providers  a vendor is named in code. The resolver and the adapter may; nothing else."
    exit 1
}

main "$@"
