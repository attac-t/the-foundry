#!/bin/sh
#
# Deny a merge that would close an issue while one of its boxes is still open.
#
# Reads a `PreToolUse` tool call as JSON on stdin. Denies a `Bash` command running `gh pr merge` on a
# request whose body, title or commits would close an issue with an unticked box.
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

    shut=$(
        numbers_after 'close[sd]*'        "$lowered"
        numbers_after 'fix[esd]*'         "$lowered"
        numbers_after 'resolve[sd]*'      "$lowered"
    )
    shut=$(printf '%s\n' $shut | sort -u)

}

# **The body, the title and each commit message.** GitHub closes from all three: a commit when it
# reaches `main`, and the title inside the merge commit. #1021 closed from a commit under `Refs`.
#
# Each line of a commit carries its hash, so a refusal names the commit that closes.
what_the_forge_reads() {
    gh pr view "$1" --json body,title,commits --jq '.body, ("merge commit: " + .title),
        (.commits[] | .oid[0:7] as $c | (.messageHeadline, (.messageBody | split("\n")[]))
            | "commit \($c): \(.)")' 2>/dev/null
}

numbers_after() {
    printf '%s' "$2" | sed -n "s/.*$1[[:space:]]*#\([0-9]\{1,\}\).*/\1/p"
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
    printf '%s' "$said" | grep -i -m1 -E "(close[sd]*|fix[esd]*|resolve[sd]*) *#$1"
}

open_boxes_on() {
    gh issue view "$1" --json body --jq .body 2>/dev/null | grep -c '^- \[ \]'
}

deny() {
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny",'
    printf '"permissionDecisionReason":"%s"}}\n' "$(safe_in_json "$1")"

    exit 0
}

# A commit quotes freely, and a refusal that does not parse refuses nothing. So a quote, a
# backslash, a tab and a carriage return are dropped, as `ticks.sh` drops them. `sh` has no parser.
safe_in_json() {
    printf '%s' "$1" | tr -d '"\\\r\t'
}

allow() { exit 0; }

main "$@"
