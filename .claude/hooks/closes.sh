#!/bin/sh
#
# Deny a merge that would close an issue while one of its boxes is still open.
#
# Reads a `PreToolUse` tool call as JSON on stdin. Denies a `Bash` command running `gh pr merge` on a
# request whose body or commits would close an issue with an unticked box, or whose title names one.
#
# **Merge and completion are two transitions, and only one of them is checked.** `ticks.sh` reports
# after the merge, which is after the lie is on the page. This is the half that comes first.
#
# On 15 September 2026 a merge closed #711 with one of five boxes open. The body ended `Refs`, and
# what fired was a sentence under *The limits* — *this closes #711's last box and nothing else.*
# **GitHub reads the keyword anywhere in the body**, so a line saying the opposite closed the issue.
#
# A box that can only be true on `main` can never tick first. That request says `Refs`, merges, and
# the issue is closed by hand against the merge tree. This refusal is what makes that the only path.
#
# **This is lint, and calling it anything stronger would be a lie.** The worker holds the same
# account and the same disk, so it closes the easy path and nothing else. `seam.sh` carries the same
# limit for comments, and #419 owns the control that binds.
#
# Exit 0 always. A hook that fails must not become a hook that blocks everything.

set -u

# What the request would close, and what the forge reads. Filled by the walk, read by the refusal.
shut=
said=

# The two reads, pinned. `tests/closes.sh` answers these exact strings and nothing else, so an edit
# goes red there until somebody measures it live again. #1027 is where both were measured.
THE_REQUEST='.url, .body, ("merge commit: " + .title)'
EACH_COMMIT_LINE='.[] | .sha[0:7] as $c | .commit.message | split("\n")[] | "commit \($c): \(.)"'

main() {
    call=$(cat)

    merges_a_request "$call" || allow

    number=$(number_in "$call")
    [ -n "$number" ] || allow

    read_what_it_would_close "$number"
    [ -n "$shut" ] || allow

    refuse_while_a_box_is_open
    allow
}

merges_a_request() {
    case $1 in
        *'gh pr merge'*) return 0 ;;
    esac

    return 1
}

# The first number after `gh pr merge`. A merge naming no number takes the branch's own request, and
# `gh` resolves that from the checkout — this cannot, so it says nothing rather than guessing.
number_in() {
    printf '%s' "$1" \
        | sed -n 's/.*gh pr merge[[:space:]]\{1,\}\([0-9]\{1,\}\).*/\1/p' | head -1
}

# **Anywhere the forge reads, in any case, and all nine words.** That is what the forge does, so a
# check reading only the last line agrees with the author's intent and not with the machine.
#
# `Refs` is not closure and is left alone.
read_what_it_would_close() {
    said=$(what_the_forge_reads "$1") || return 0

    # Lowered once, so each pattern says the word rather than spelling both cases of every letter.
    lowered=$(printf '%s' "$said" | tr 'A-Z' 'a-z')

    shut=$(numbers_closed_in "$lowered" | sort -u)
}

# **The body and every commit message, whole.** GitHub closes from the body, and from a commit when
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

refuse_while_a_box_is_open() {
    for issue in $shut; do
        open=$(open_boxes_on "$issue")

        [ "$open" -gt 0 ] 2>/dev/null || continue

        deny "this merge would close #$issue with $open box(es) still open. The line that closes it is [$(line_closing "$issue")]. Tick what holds against the merge tree, or say Refs and close it by hand with a receipt."
    done
}

# **The line for this issue, never the first one read.** A body closing two issues quoted the
# wrong one, and the author read a sentence they had not written.
line_closing() {
    printf '%s' "$said" | grep -i -m1 -E "(close[sd]*|fix[esd]*|resolve[sd]*):? *#$1([^0-9]|\$)"
}

open_boxes_on() {
    gh issue view "$1" --json body --jq .body 2>/dev/null | grep -c '^- \[ \]'
}

deny() {
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny",'
    printf '"permissionDecisionReason":"%s"}}\n' "$(safe_in_json "$1")"

    exit 0
}

# A commit quotes freely, and a refusal that does not parse refuses nothing. So a quote, a backslash
# and every control character JSON forbids are dropped. `ticks.sh` drops the first two, as `sh` has
# no parser to escape them with.
safe_in_json() {
    printf '%s' "$1" | tr -d '"\\\000-\037'
}

allow() { exit 0; }

main "$@"
