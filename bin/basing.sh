#!/bin/sh
#
# Name every file a branch would delete that the branch never touched.
#
# **A branch cut before a merge deletes what that merge landed.** Git reports no conflict, because
# the branch never held the file. The merge is clean and the diff removes shipped work.
#
# It happened four times on the morning of 15 September 2026, in three rounds. Each round was found
# by hand, by merging and reading a stat line. **Nothing else said a word.**
#
# `.claude/rules/basing.md` has held this since 6 September and says no exit code can. **That is true
# of a gate and false of a check**: a gate reads one tree, and this reads two refs.
#
# Usage: sh bin/basing.sh [<target>]      # default: origin/main
#        sh bin/basing.sh audit           # drive tests/basing.sh
#
# Exit codes:
#
#   0   nothing is deleted that this branch never touched
#   1   a file the branch never names loses lines, and each is printed
#   2   asked for something this does not do, or there is no repository here
#   3   a merge is unresolved, so the diff would name every merge this branch predates
#
set -u


say()  { printf '%s\n' "$1"; }
note() { printf 'basing: %s\n' "$1" >&2; }

main() {
    # **The audit runs from this repository; the check runs from the caller's.** A `cd` at the top
    # made every reading about this checkout, and the suite's own fixtures passed by accident.
    [ "${1:-}" = audit ] && { cd "$(dirname "$0")/.." || exit 2; drive_the_suite; return $?; }
    [ "$#" -le 1 ] || { note 'takes one target, or audit'; exit 2; }

    target=${1:-origin/main}

    inside_a_repository   || { note 'no repository here'; exit 2; }
    refuse_an_open_merge
    refuse_a_target_that_is_not_there "$target"

    name_what_would_go "$target"
}

drive_the_suite() {
    [ -f tests/basing.sh ] || { note 'tests/basing.sh is not here, so this read nothing'; exit 2; }

    bash tests/basing.sh
}

inside_a_repository() { git rev-parse --git-dir >/dev/null 2>&1; }

#
# **A stat taken mid-conflict wears the tell's clothes.** While a merge is unresolved `HEAD` is still
# the old commit, so the diff reports every merge this branch predates as a deletion.
#
# On 14 September that read as 99 deletions across five files, every one of them landed work.
# Resolved and committed, the same command said two files and nothing deleted.
#
refuse_an_open_merge() {
    a_merge_is_open || return 0

    note 'a merge is unresolved here, and a diff taken now names work this branch merely predates'
    note 'resolve it, commit, and ask again'
    exit 3
}

a_merge_is_open() { [ -f "$(git rev-parse --git-dir)/MERGE_HEAD" ]; }

refuse_a_target_that_is_not_there() {
    git rev-parse --verify --quiet "$1" >/dev/null && return 0

    note "[$1] is not a ref here. Fetch first, or name another"
    exit 2
}

#
# **The files this branch touched, against the files the diff removes lines from.** A deletion in the
# first is the branch's own work. A deletion in the second and not the first is what this exists for.
#
# **Two trees, never `...`.** Three dots compares against the merge base, and a file the target
# added after the cut is simply absent there — so the deletion this exists to name never appears.
# The list of what the branch touched still uses `...`, because that is its own work.
#
name_what_would_go() {
    kept=${TMPDIR:-/tmp}/basing-$$
    git diff --name-only "$1...HEAD" > "$kept"

    # **Through a file, and `-f`.** `-e` takes one pattern and this list is many lines. A path
    # holding a regex character would be a pattern too, which `-F` refuses.
    unnamed=$(git diff --numstat "$1" HEAD \
        | awk '$2 != "0" && $2 != "-" { print $3 }' \
        | grep -vxF -f "$kept")

    rm -f "$kept"

    [ -n "$unnamed" ] || { say 'basing   nothing this branch never touched loses a line'; return 0; }

    say 'basing   these lose lines and this branch never touched them:'
    printf '%s\n' "$unnamed" | sed 's/^/           /'
    say ''
    say '         merge the target in, then read the stat again:'
    say "           git merge --no-edit $1 && git diff --stat $1 HEAD"

    exit 1
}

main "$@"
