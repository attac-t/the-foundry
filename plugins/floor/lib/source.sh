#!/bin/sh
#
# Which work source answers here.
#
# This and the two files it names are the only ones in floor that may know a provider exists. The
# run records an item's id and the item's own words. It never learns which source said them, so a run
# moved to a machine with none of these installed still means what it meant.
#
# GitHub when the remote is GitHub and `gh` is present — RFC-001 §3's level 1. **A GitHub remote with
# no `gh` is answered by nothing**: every verb exits 3, *could not be asked*, and names `gh`. A
# directory has never heard of Issues, so its *nothing there* would be a fact nobody observed. #1132.
#
# The directory adapter answers every other remote. `FOUNDRY_SOURCE` names it for a GitHub one, and
# that is a host's choice, never this file's.
#
# `exec`, so whichever answers reports its own exit code and nothing translates it.
#
# Usage: sh source.sh <verb> <argument...>
#
# Exit: the adapter's own, or 3 when the remote is GitHub and nothing here can ask it
#

set -u
here=$(dirname "$0")

# `origin`, as `git remote get-url origin` prints it, holds `github.com`. A GitHub reached through an
# alias, or on a host named otherwise, reads as not GitHub, and the directory answers it unsaid.
remote_is_github() {
    case "$(git remote get-url origin 2>/dev/null)" in
        *github.com*) return 0 ;;
    esac

    return 1
}

gh_is_here() { command -v gh >/dev/null 2>&1; }

# Answered here, never passed on. `join.sh` kept its own copy of this test, which
# put a provider's name in core and made the line above false the day it was written.
#
# 3 when nothing answers, as every verb exits then. `join.sh` refuses a host on that 3 alone.
say_what_answers() {
    remote_is_github || { printf 'a directory — this remote is not GitHub\n'; return 0; }
    gh_is_here || { say_nothing_answers; return 3; }

    say_whether_gh_can_answer
}

# **The sign-in is read here, and routing never reads it.** It reaches the network, so every verb would
# pay for a call. A signed-out `gh` is refused inside the adapter, and `read` and `publish` say so in its words.
#
# `api user` answers only when the account `gh` would use does. `auth status` fails when any account
# fails, and `--active`, which narrows it, is not in the `gh` Debian ships. #1132's judge, round one.
say_whether_gh_can_answer() {
    said=$(gh api user 2>&1 >/dev/null) && { printf 'GitHub\n'; return 0; }

    printf 'nothing answers: the remote is GitHub, and gh api user failed. gh said:\n%s\n' "$said"
    return 3
}

# Two lines, so `join.sh` can set the second under the first. The path is whole, as a setting wants it.
say_nothing_answers() {
    printf 'nothing answers: the remote is GitHub, and gh is not here\n'
    printf 'Install gh, or name the directory adapter: FOUNDRY_SOURCE=%s/source-dir.sh\n' "$(cd "$here" && pwd)"
}

# A directory answering would say *nothing there* about an item it never held, so nothing does.
refuse_without_gh() {
    say_nothing_answers | sed 's/^/source: /' >&2
    exit 3
}

[ "${1:-}" = serves ] && { say_what_answers; exit "$?"; }

remote_is_github || exec sh "$here/source-dir.sh" "$@"
gh_is_here || refuse_without_gh

exec sh "$here/source-github.sh" "$@"
