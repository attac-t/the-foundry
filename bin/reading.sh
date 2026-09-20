#!/bin/sh
#
# How much a person must read to follow this repository.
#
# **A human surface is a decision interface, never a transcript**, and the only way to know whether
# that holds is to count. The first count was taken on 25 August 2026 and never again, which is what
# #835 is.
#
# **Words, because a reader spends time and not bytes.** A table renders to fewer words than the
# paragraph it replaced, and that is the point of the table.
#
# **The 90th percentile is the one that matters.** A median of two hundred words hides a comment of
# three thousand, and the reader who meets that one is the reader who stops.
#
# Usage: sh bin/reading.sh [<count>]      default 100, the sample the first measure used
#
# Exit: 0 it measured, 3 a forge could not be asked.
#
# Not a gate, and never a verdict. `.claude/rules/writing.md` says why no exit code can judge prose.
# **This is an alert.** A number that moved is a reason to read, not a reason to refuse.
#
# **Two measures are refused here, and each would be gamed the same day it shipped.**
#
# *Comment count* rewards a quiet thread. A reviewer who asks three sharp questions scores worse
# than one who asks none, and the cheapest way to improve is to stop replying.
#
# *A word ceiling that fails a build* rewards deleting the qualifier that made a claim true. Short
# and wrong passes it. `signal:economy` names that as the worst outcome of all, and it is why this
# prints a number and returns zero.

set -eu

readonly HOW_MANY="${1:-100}"

say()  { printf '%s\n' "$*"; }
note() { printf '%s\n' "$*" >&2; }

main() {
    refuse_without_a_forge

    say "reading — the last $HOW_MANY of each, measured $(date -u '+%d %B %Y')."
    say ''
    say 'kind        median   p75   p90  longest  >300  >600'

    measure issues   "$(words_in_issues)"
    measure requests "$(words_in_requests)"
    measure comments "$(words_in_comments)"

    say ''
    say 'reading — a count is an alert. The words a reader cannot skip are what it stands for.'
}

refuse_without_a_forge() {
    command -v gh >/dev/null 2>&1 && return 0

    note 'reading — this asks a forge, and no `gh` is on this host. Nothing was measured'
    exit 3
}

#
# One word count per body, one per line.
#
# **A pull request is not an issue**, and the REST list for issues returns both. The two are asked
# for separately so neither borrows the other's shape.
words_in_issues() {
    gh api "repos/{owner}/{repo}/issues?state=all&per_page=$HOW_MANY" \
       --jq '.[] | select(has("pull_request") | not) | .body // "" | split(" ") | length' \
       2>/dev/null || refuse_a_half issue
}

words_in_requests() {
    gh api "repos/{owner}/{repo}/pulls?state=all&per_page=$HOW_MANY" \
       --jq '.[] | .body // "" | split(" ") | length' 2>/dev/null || refuse_a_half request
}

# Every comment on the repository, newest first. A comment is where the first measure found its
# worst case, at 2,873 words.
words_in_comments() {
    gh api "repos/{owner}/{repo}/issues/comments?sort=created&direction=desc&per_page=$HOW_MANY" \
       --jq '.[] | .body // "" | split(" ") | length' 2>/dev/null || refuse_a_half comment
}

refuse_a_half() {
    note "reading — the $1 half could not be read. Nothing is claimed about it"
    exit 3
}

#
# **Sorted once, then read by index.** A percentile over an unsorted list is a number with the right
# shape and no meaning, and nothing about the output would say so.
measure() {
    printf '%s\n' "$2" | grep . | sort -n | awk -v kind="$1" '
        { n[NR] = $1 }

        END {
            if (NR == 0) { printf "%-10s  nothing to read\n", kind; exit }

            printf "%-10s %6d %5d %5d %8d %5d %5d\n", kind,
                   at(50), at(75), at(90), n[NR],
                   over(300), over(600)
        }

        function at(p,   i) { i = int(NR * p / 100); return n[i < 1 ? 1 : i] }
        function over(w,   i, c) { for (i = 1; i <= NR; i++) if (n[i] > w) c++; return c }
    '
}

main "$@"
