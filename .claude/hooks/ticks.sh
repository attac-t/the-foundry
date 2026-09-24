#!/bin/sh
#
# After a merge, say which issues it closed and how many of their boxes nobody ticked.
#
# `Closes #N` is a GitHub feature. It flips the state and never touches the body, so an issue closed
# by a merge records nothing about which of its claims held. Eighteen boxes went blank on 4
# September and fourteen more on 9 September, and both were found only because someone went looking.
#
# `bin/unticked.sh` already finds them, `CONTRIBUTING.md` already says to run it after a `Closes`
# merge, and nothing runs it. **A usage line has been measured here at nought out of thirteen.**
# This is that instruction where it fires on its own.
#
# It reports and never ticks. A tick is a judgement — did this box hold? — and
# `.claude/rules/closing.md` keeps that with a person.
#
# Reads a `PostToolUse` tool call as JSON on stdin.
#
# Exit 0 always. A hook that fails must not become a hook that blocks everything.

set -u

# The reads the merge hook uses, so the two hooks agree on what a merge closed. #1033.
. "$(dirname "$0")/forge-reads.sh"

main() {
    call=$(cat)

    merges_a_request "$call" || exit 0

    number=$(number_in "$call")
    [ -n "$number" ] || exit 0

    report_each_issue_it_closes "$number"
}

merges_a_request() {
    case $1 in
        *'gh pr merge'*) return 0 ;;
    esac

    return 1
}

# The first number after `gh pr merge`. A merge naming no number takes the branch's own request and
# `gh` resolves that from the checkout — this cannot, so it says nothing rather than guessing.
number_in() {
    printf '%s' "$1" \
        | sed -n 's/.*gh pr merge[[:space:]]\{1,\}\([0-9]\{1,\}\).*/\1/p' | head -1
}

# What the merge closed, read as `closes.sh` reads it: the body, the title and each commit message,
# with all nine words. It heard only `Closes`, in the body alone, until #1033.
issues_closed_by() {
    forge_text=$(what_the_forge_reads "$1") || return 0

    numbers_closed_in "$(printf '%s' "$forge_text" | tr 'A-Z' 'a-z')" | sort -u
}

report_each_issue_it_closes() {
    said=''

    for issue in $(issues_closed_by "$1"); do
        said="$said$(what_is_open "$issue")"
    done

    [ -n "$said" ] || exit 0

    inject "$said"
}

# Silence when every box is ticked, because that is the ordinary case and a hook that speaks every
# time is one a reader stops seeing.
what_is_open() {
    open=$(gh issue view "$1" --json body --jq .body 2>/dev/null | grep -c '^- \[ \]')

    [ "${open:-0}" -gt 0 ] 2>/dev/null || return 0

    printf '#%s closed by this merge with %s open; ' "$1" "$open"
}

#
# **Through `additionalContext`, never stdout.** Only SessionStart, UserPromptSubmit and Setup
# inject what a hook prints; on a tool event it reaches the transcript and nobody reads it back.
#
# This shipped printing plainly and nothing ever saw it speak. Floor's own suite carried the
# reasoning and caught the same mistake in a plugin hook a day later — a repository-level hook had
# no such suite until now.
#
# One line, no quote and no backslash. Building JSON in `sh` is a parser this does not have.
inject() {
    printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":'
    printf '"%sread each box against the tree, then tick it, strike it, or move it."}}\n' \
        "$(printf '%s' "$1" | tr -d '"\\')"
}

main "$@"
