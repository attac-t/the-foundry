#!/bin/sh
#
# Open issues the board does not carry.
#
# **The board is the front door**, and `README.md` says so: it is where a stranger starts and the
# only page that answers what needs eyes and what is next. An issue missing from it is filed and
# invisible.
#
# **It has happened twice.** Four new issues were once all off it, and on 20 September two filed
# that day were too. Both times a person noticed by looking, and nothing else would have.
#
# **Two sources, and one of them lies quietly.** A project read is GraphQL, which is the bucket a
# room full of workers empties first — an empty answer reads the same as a board carrying nothing.
# So an empty board refuses rather than reporting every issue as missing.
#
# The owner comes from `origin`, never from a name written here. The board is `FOUNDRY_BOARD`, and
# 1 is this repository's only because `README.md` says so.
#
# Usage: sh bin/offboard.sh
#
# Exit: 0 every open issue is on the board, 1 at least one is not, 3 a source could not be asked.
#
# Not a gate. It reaches the network, and `.claude/rules/plugins.md` refuses a gate that goes red
# on a train. `CONTRIBUTING.md` lists it beside the other checks a person runs.

set -eu

readonly BOARD="${FOUNDRY_BOARD:-1}"
readonly carried="${TMPDIR:-/tmp}/offboard-carried.$$"
readonly open_now="${TMPDIR:-/tmp}/offboard-open.$$"

note() { printf '%s\n' "$*" >&2; }
say()  { printf '%s\n' "$*"; }

main() {
    trap 'rm -f "$carried" "$open_now"' EXIT

    refuse_without_a_forge

    owner=$(owner_in_origin) || refuse_without_an_owner

    numbers_the_board_carries "$owner" > "$carried" || refuse_a_half_that_would_not_read board
    numbers_open_here                  > "$open_now" || refuse_a_half_that_would_not_read issue

    refuse_an_empty_board

    report
}

refuse_without_a_forge() {
    command -v gh >/dev/null 2>&1 && return 0

    note 'offboard — both halves read a forge, so an adapter is the whole of it'
    note 'offboard — no `gh` on this host. Nothing was read and nothing is claimed'
    exit 3
}

# Named here rather than written down, so this file carries no account.
refuse_without_an_owner() {
    note 'offboard — `origin` does not say who owns this repository, so no board can be found'
    exit 3
}

refuse_a_half_that_would_not_read() {
    note "offboard — the $1 half could not be read. Nothing was judged"
    exit 3
}

#
# **An empty board and a board nobody could read are the same answer here.** Reporting every open
# issue as missing is the loudest possible way to be wrong, and a rate limit produces exactly that.
refuse_an_empty_board() {
    [ -s "$carried" ] && return 0

    note "offboard — board $BOARD carries nothing. Either that is true, or the read was refused"
    exit 3
}

# `github.com/<owner>/<repo>`, in either spelling `git remote` hands back.
owner_in_origin() {
    said=$(git remote get-url origin 2>/dev/null) || return 1

    printf '%s' "$said" | sed -n 's#^.*[:/]\([^/:]*\)/[^/]*$#\1#p' | grep .
}

#
# Every issue and request the board holds, as numbers. A draft item carries no number and is not
# one of these, which is why the field is asked for rather than counted.
numbers_the_board_carries() {
    gh project item-list "$BOARD" --owner "$1" --format json --limit 500 \
       --jq '.items[] | .content.number // empty' 2>/dev/null
}

# `select(has("pull_request") | not)` because REST counts a request as an issue and the board holds
# both. A request is not the front door's subject.
numbers_open_here() {
    gh api "repos/{owner}/{repo}/issues?state=open&per_page=100" --paginate \
       --jq '.[] | select(has("pull_request") | not) | "\(.number)\t\(.title)"' 2>/dev/null
}

#
# Newest first, because a run of missing numbers at the top is the shape this fault takes: somebody
# filed and moved on.
report() {
    missing=$(awk -F'\t' 'NR == FNR { on[$1] = 1; next } !($1 in on)' "$carried" "$open_now" \
              | sort -t'	' -k1,1nr)

    [ -n "$missing" ] && say_the_rows "$missing" && return 1

    say "offboard — every open issue is on board $BOARD. Nothing is filed and invisible."
    return 0
}

say_the_rows() {
    say "offboard — $(printf '%s\n' "$1" | grep -c .) open issues are not on board $BOARD:"
    say ''

    printf '%s\n' "$1" | while IFS='	' read -r number title; do
        printf '  #%-5s %s\n' "$number" "$title"
    done

    say ''
    say 'offboard — a stranger starts at the board, so an issue missing from it is filed and unread.'
}

main "$@"
