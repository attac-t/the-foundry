#!/bin/sh
#
# What a merge would close, read the way the forge reads it. `closes.sh` sources this before a
# merge and `ticks.sh` after one, so the two hooks cannot disagree about what a merge closed.

# The two reads, pinned. `tests/closes.sh` and `tests/ticks.sh` answer these exact strings and nothing else, so an edit
# goes red there until somebody measures it live again. #1027 is where both were measured.
THE_REQUEST='.url, .body, ("merge commit: " + .title)'
EACH_COMMIT_LINE='.[] | .sha[0:7] as $c | .commit.message | split("\n")[] | "commit \($c): \(.)"'

# **The body and each commit message, whole.** GitHub closes from the body, and from a commit when
# it reaches `main`. #1021 closed from a commit while the body said `Refs`.
#
# The title is read by choice. It rides in the merge commit, and whether that closes is unmeasured.
# Reading it can only refuse more than GitHub closes, which costs a retitle and never a wrong close.
# A merge given `-t`, `-b` or `-F` writes its own merge message, and nothing here reads that.
#
# The commits come from the REST list, whole, and GitHub documents that the list stops at 250.
# `gh pr view` cuts a headline near seventy characters, and it cut twelve of #1027's subjects.
#
# A commit read that fails leaves the body's check standing. Its status is dropped, and whatever it
# printed is only more text to search.
what_the_forge_reads() {
    request=$(gh pr view "$1" --json url,body,title --jq "$THE_REQUEST" 2>/dev/null) || return 1

    printf '%s\n' "$request" | sed 1d
    commits_of "$(repository_in "$request")" "$1"
    return 0
}

# The request's own address, so both reads name one request. `{owner}` in a `gh api` path follows
# the directory, and in a clone of a fork it has named the upstream.
repository_in() {
    printf '%s\n' "$1" | sed -n '1s#^https\{0,1\}://[^/]*/\([^/]*/[^/]*\)/pull/[0-9]*$#\1#p'
}

# One line per line of each message, carrying its commit's hash, so a refusal names the commit.
commits_of() {
    [ -n "$1" ] || return 0

    gh api "repos/$1/pulls/$2/commits" --paginate --jq "$EACH_COMMIT_LINE" 2>/dev/null
}

# **Every match on a line, and a colon allowed.** `Closes: #10` closes, and so does each issue in
# `Resolves #10, resolves #123`. A pattern keeping the last match read only the second.
numbers_closed_in() {
    printf '%s\n' "$1" | awk '{
        while (match($0, /(close[sd]*|fix[esd]*|resolve[sd]*):?[ \t]*#[0-9]+/)) {
            hit = substr($0, RSTART, RLENGTH); sub(/.*#/, "", hit); print hit
            $0 = substr($0, RSTART + RLENGTH)
        }
    }'
}
