#!/bin/sh
#
# Which work source answers here.
#
# **This and the two files it names are the only ones in floor that may know a provider exists.** The
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

github_serves() {
    command -v gh >/dev/null 2>&1 || return 1

    case "$(git remote get-url origin 2>/dev/null)" in
        *github.com*) return 0 ;;
    esac

    return 1
}

github_serves && exec sh "$here/source-github.sh" "$@"

exec sh "$here/source-dir.sh" "$@"
