#!/bin/sh
#
# Deny an automated GitHub comment that did not come through the seam.
#
# Reads a `PreToolUse` tool call as JSON on stdin. Denies a `Bash` command that writes a comment
# whose body does not carry the marker `plugins/floor/bin/say.sh` renders.
#
# **This is lint, and calling it anything stronger would be a lie.** The worker can edit this file,
# change the matcher, or unset the hook — it holds the same account and the same disk. Two
# architecture consultations at maximum effort said so independently, and neither hedged:
#
#   an agent-editable hook is theatre as an adversarial control, and useful against accidental misuse
#   the human holds the token, the branch rules, the workflow and their inbox
#
# So this closes the easy path and nothing else. #419 owns the control that binds: a comment
# credential the automated worker cannot reach. `bin/comments.sh` reads the public thread back,
# which is detection after disclosure, not prevention.
#
# Exit 0 always. A hook that fails must not become a hook that blocks everything.

set -u

main() {
    call=$(cat)

    writes_a_body "$call" || allow
    carries_the_marker "$call" && allow

    deny "a public comment is rendered by plugins/floor/bin/say.sh, which takes fields and refuses six ways. This command carries no seam marker. Run say.sh and post what it printed."
}

#
# A comment write that carries a body. `gh pr review --approve` carries none, and denying it stopped
# a legitimate action for lacking a marker it could never have.
#
writes_a_body() {
    carries_no_body "$1" && return 1

    case $1 in
        *'gh pr comment'*|*'gh issue comment'*|*'gh pr review'*) return 0 ;;
        *'issues/'*'/comments'*|*'pulls/'*'/comments'*)          return 0 ;;
    esac
    return 1
}

# `gh pr review --approve` carries nothing to render, so nothing here may deny it.
#
# The short forms count. `-b` is `--body` and `-F` is `--body-file`, and a guard that reads only the
# long ones lets the exact command it exists to stop through, one character shorter.
carries_no_body() {
    case $1 in
        *--body*|*' -b '*|*' -F '*) return 1 ;;
    esac
    return 0
}

#
# The whole marker, in the command or in the file it names.
#
# A rendered body arrives as `--body-file`, so the marker is in the file and never on the command
# line — which is how this denied its own author the first time it ran. Reading the named file
# checks what actually gets posted.
#
# `seam:` alone was enough once. Any log mentioning the word walked through, which is the shape this
# exists to stop.
carries_the_marker() {
    case $1 in *'<!-- seam:'*' -->'*) return 0 ;; esac

    # Shell, never a regex. A `sed` backreference is the one line here that a copy through another
    # tool has already silently broken, twice.
    #
    # The quote goes first, turned into a space, so no pattern below has to contain one.
    said=$(printf '%s' "$1" | tr '"' ' ')
    named=${said#*--body-file}
    named=${named#=}
    named=${named# }
    named=${named%% *}

    [ "$named" != "$said" ] || return 1
    [ -n "$named" ] || return 1
    grep -q '<!-- seam:' "$named" 2>/dev/null
}

deny() {
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny",'
    printf '"permissionDecisionReason":"%s"}}
' "$1"
    exit 0
}

allow() { exit 0; }

main "$@"
