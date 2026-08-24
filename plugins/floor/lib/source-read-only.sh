#!/bin/sh
#
# A work source that can only be read. The third adapter, and the smallest one that is still valid.
#
# §2.1 proposes four operations and this answers one. A source that cannot be written to is a real
# shape — an issue tracker nobody may post to, an export, a file someone handed you — and a contract
# admitting only four-verb sources would make those unusable rather than limited.
#
# Every other verb exits 2. Core reads that as this source having no
# way, and refuses at 27, which is a different fact
# from a source that failed today.
#
#     items/<item>                   what someone wants
#
# Not selected by `source.sh`, which chooses between the two that can answer everything. `FOUNDRY_SOURCE`
# names this one, so a repository opts into a source that is less than four verbs.
#
# Usage: sh source-read-only.sh read <item>
#
# Exit: 0 answered · 1 nothing there · 2 asked for something this does not do · 3 it could not read
#

set -u

root=${FOUNDRY_SOURCE_DIR:-${FOUNDRY_HOME:-${HOME:-.}/.foundry}/source}

# What someone wants, as they wrote it. Absent is one answer and unreadable is another, and `cat`
# failing after `[ -f ]` passed used to report the second as the first.
read_item() {
    [ -f "$root/items/$1" ] || return 1
    [ -r "$root/items/$1" ] || return 3

    cat "$root/items/$1"
}

# Named rather than inlined, because the exit code is the contract and one
# place decides it, never two.
cannot() {
    echo "source-read-only: this source can only be read" >&2
    exit 2
}

case "${1:-}" in
    read)                      shift; read_item "${1:-}" ;;
    publish|ask|receive|kind|claim|held|release)  cannot ;;
    *)                         echo "source-read-only: read <item>" >&2; exit 2 ;;
esac
