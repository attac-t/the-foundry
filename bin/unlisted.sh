#!/bin/sh
#
# Closed issues that recorded nothing, and the open work still pointing at them.
#
# **A closed issue is not an owner**, and `.claude/rules/closing.md` says so. This finds the ones
# being treated as one: closed with no `- [ ]` box at all, so closing recorded nothing about any
# claim, while an open issue or a tracked page still sends a reader there.
#
# **Not the same as a list nobody ticked.** `bin/unticked.sh` reads a closed list with a box left
# open. This reads a closed issue that never had a box, which is worse to find and cheaper to
# answer: an unrecordable claim is unverified, and it becomes work the day something contradicts it.
#
# **No count here.** The report's first line is the number, and a number in a header goes stale the
# day after it is written.
#
# Usage: sh bin/unlisted.sh
#
# Exit: 0 nothing is relied on, 1 at least one is, 3 the forge could not be asked.
#
# Not a gate. It reaches the network, and `.claude/rules/plugins.md` refuses a gate that goes red
# on a train. `CONTRIBUTING.md` lists it beside the other checks a person runs.

set -eu

readonly TAB="$(printf "\t")"
readonly listless="${TMPDIR:-/tmp}/unlisted-closed.$$"
readonly named="${TMPDIR:-/tmp}/unlisted-named.$$"

note() { printf '%s\n' "$*" >&2; }
say()  { printf '%s\n' "$*"; }

main() {
    trap 'rm -f "$listless" "$named"' EXIT

    refuse_without_a_forge

    closed_with_no_list > "$listless" || refuse_a_half_that_would_not_read closed
    open_work_names     > "$named"    || refuse_a_half_that_would_not_read open

    refuse_an_empty_read

    report
}

#
# Both halves read issues. Unlike `unread`, no part of this still works without a forge, and saying
# so beats a silent empty answer that reads like a clean bill.
refuse_without_a_forge() {
    command -v gh >/dev/null 2>&1 && return 0

    note 'unlisted — both halves read issues, so a forge adapter is the whole of it'
    note 'unlisted — no `gh` on this host. Nothing was read and nothing is claimed'
    exit 3
}

# Which half failed is the only thing a caller cannot work out afterwards.
refuse_a_half_that_would_not_read() {
    note "unlisted — the $1 issues could not be read. Nothing was judged"
    exit 3
}

#
# A repository with no closed issue at all is real. One where the forge answered with silence is
# not, and the join cannot tell them apart — two empty sets agree, and agreeing on nothing is how a
# report certifies nothing.
refuse_an_empty_read() {
    [ -s "$listless" ] && return 0

    note 'unlisted — not one closed issue here lacks a list. Either that is true, or the forge said nothing'
    exit 3
}

#
# Every closed issue whose body holds no box at all, as `number<TAB>title`.
#
# **REST, and that is not a preference.** GraphQL is the bucket a room full of workers empties
# first. `select(has("pull_request") | not)` because REST counts a request as an issue.
closed_with_no_list() {
    gh api "repos/{owner}/{repo}/issues?state=closed&per_page=100" --paginate \
       --jq '.[]
             | select(has("pull_request") | not)
             | select(((.body // "") | test("- \\[[ xX]\\] ")) | not)
             | "\(.number)\t\(.title)"' 2>/dev/null
}

#
# Every issue number open work names, as `number<TAB>where`.
#
# **Two sources, because a pointer is a pointer.** An open issue's body is one. A tracked page is
# the other, and `.foundry/status.md` held two of them — a reader followed either link, found a
# closed page, and read the gap as handled.
open_work_names() {
    open_issues_name
    tracked_pages_name
}

open_issues_name() {
    gh api "repos/{owner}/{repo}/issues?state=open&per_page=100" --paginate \
       --jq '.[]
             | select(has("pull_request") | not)
             | . as $i
             | ((.body // "") | [scan("#[0-9]+")] | unique | .[])
             | "\(. | ltrimstr("#"))\t#\($i.number)"' 2>/dev/null
}

#
# Tracked, never every file. An untracked note is one person's and a clone never sees it, so a
# pointer nobody else can follow is not a pointer this report is about.
tracked_pages_name() {
    git grep -ohE '#[0-9]+' -- '*.md' 2>/dev/null |
        sort -u |
        awk -v t="$TAB" '{ print substr($0, 2) t "a tracked page" }'
}

#
# One row per closed issue something still points at, most pointed-at first.
report() {
    rows=$(join_the_two | sort -t"$TAB" -k1,1nr)

    [ -n "$rows" ] && say_the_rows "$rows" && return 1

    say 'unlisted — nothing closed and empty is being pointed at. Nobody is relying on silence.'
    return 0
}

say_the_rows() {
    say "unlisted — $(printf '%s\n' "$1" | grep -c .) closed issues recorded nothing, and open work still points at them:"
    say ''

    printf '%s\n' "$1" | while IFS="$TAB" read -r count number title from; do
        printf '%5s  #%-5s %s\n' "$count" "$number" "$title"
        printf '        %s\n' "$from"
    done

    say ''
    say 'unlisted — read each against the tree and say what still holds. None of this reopens anything.'
}

#
# `count<TAB>number<TAB>title<TAB>who points`, for every closed empty issue with at least one
# pointer. A closed issue nothing names is history, and history is not this report's subject.
join_the_two() {
    awk -F"$TAB" -v t="$TAB" '
        NR == FNR { title[$1] = $2; next }
        !($1 in title) { next }
        { seen[$1]++
          if (index(from[$1], $2) == 0) from[$1] = from[$1] " " $2 }
        END { for (n in seen) print seen[n] t n t title[n] t substr(from[n], 2) }
    ' "$listless" "$named"
}

main "$@"
