#!/bin/sh
#
# Fails when a merge lands two changes to one plugin under one version.
#
# **Git catches the loud half already.** Two branches writing different numbers to the same line
# conflict, and the merge stops until a person picks. That case needs no gate and gets none here.
#
# The quiet half is this. Both branches cut from the same base, both read the same version, and both
# write the same next one. Every side writes an identical line, so git merges them clean — and the
# file then says one change landed where two did.
#
# Measured 8 September 2026: four branches all wrote `0.75.5` over `0.75.4`, and nothing complained.
#
# Only a merge commit can carry it, so only a merge commit is graded. A single-parent HEAD passes and
# says why — it is not a clean check being claimed, it is a fault that cannot be there.
#
# Usage: sh bin/bumps.sh
#
# Exit: 0 clean, 1 two changes under one number, 3 the gate could not read
#
set -u

cd "$(dirname "$0")/.." || exit 3

say()  { printf '%s\n' "$1"; }
fail() { printf 'bumps: %s\n' "$1" >&2; exit 3; }

head_is_a_merge() { [ -n "$(git rev-parse --verify -q HEAD^2 2>/dev/null)" ]; }

version_at() {
    git show "$1:plugins/$2/.claude-plugin/plugin.json" 2>/dev/null \
        | sed -n 's/.*"version": "\([^"]*\)".*/\1/p'
}

plugins_here() { git ls-tree --name-only HEAD plugins/ | sed 's#plugins/##; s#/$##'; }

# Both parents moved it, and both moved it to the same place. Either one alone is a normal bump, and
# the two agreeing on a number neither started from is the fault.
both_moved_it_the_same_way() {
    [ -n "$2" ] && [ "$1" = "$2" ] && [ "$1" != "$3" ]
}

report_each() {
    base=$(git merge-base HEAD^1 HEAD^2) || fail 'the two parents share no base'
    caught=0

    for name in $(plugins_here); do
        ours=$(version_at HEAD^1 "$name")
        theirs=$(version_at HEAD^2 "$name")
        was=$(version_at "$base" "$name")

        both_moved_it_the_same_way "$ours" "$theirs" "$was" || continue

        say "  $name — both sides moved $was to $ours, so one number carries two changes"
        caught=$((caught + 1))
    done

    return "$caught"
}

main() {
    [ "$#" -eq 0 ] || fail 'this takes no argument'
    git rev-parse --git-dir >/dev/null 2>&1 || fail 'not a git repository'

    head_is_a_merge || {
        say 'PASS — HEAD is not a merge, so no two sides can have written one number.'
        exit 0
    }

    report_each && {
        say 'PASS — no plugin was bumped to the same version by both sides of this merge.'
        exit 0
    }

    say ''
    say 'FAIL — a merge landed two changes under one version. Bump it once more, by hand.'
    exit 1
}

main "$@"
