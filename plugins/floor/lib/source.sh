#!/bin/sh
#
# Which work source answers here.
#
# This and the two files it names are the only ones in floor that may know a provider exists. The
# run records an item's id and the item's own words. It never learns which source said them, so a run
# moved to a machine with none of these installed still means what it meant.
#
# GitHub when the remote is GitHub and `gh` is present — RFC-001 §3's level 1, and both halves
# matter. `gh` is not in floor's dependency contract, so the directory adapter is what answers
# otherwise, and it needs nothing floor does not already declare.
#
# `exec`, so whichever answers reports its own exit code and nothing translates it.
#
# Usage: sh source.sh <verb> <argument...>
#

set -u
here=$(dirname "$0")

remote_is_github() {
    case "$(git remote get-url origin 2>/dev/null)" in
        *github.com*) return 0 ;;
    esac

    return 1
}

github_serves() { command -v gh >/dev/null 2>&1 && remote_is_github; }

# Answered here, never passed on. `join.sh` kept its own copy of this test, which
# put a provider's name in core and made the line above false the day it was written.
say_what_answers() {
    remote_is_github || { printf 'a directory — this remote is not GitHub\n'; return; }

    command -v gh >/dev/null 2>&1 ||
        { printf 'a directory, and the remote is GitHub. Install gh, or Issues stay unreachable.\n'; return; }

    gh auth status >/dev/null 2>&1 ||
        { printf 'GitHub, but gh is not signed in. Run: gh auth login && gh auth setup-git\n'; return; }

    printf 'GitHub\n'
}

[ "${1:-}" = serves ] && { say_what_answers; exit 0; }

github_serves && exec sh "$here/source-github.sh" "$@"

# A GitHub remote whose `gh` is missing is half of level 1. The directory answers, correctly,
# but has never heard of Issues, so its nothing-there reads the same as an item nobody
# can reach. Said once on stderr, and the exit code stays the adapter's.
remote_is_github && echo "source: the remote is GitHub and gh is not here — a directory is answering" >&2

exec sh "$here/source-dir.sh" "$@"
