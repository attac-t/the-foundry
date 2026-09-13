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

# The file the guard opened, so a refusal can name it. Empty when no body file was resolved.
unread=

main() {
    call=$(cat)

    writes_a_body "$call" || allow
    carries_the_marker "$call" && allow

    deny "a public comment is rendered by plugins/floor/bin/say.sh, which takes fields and refuses six ways. $(what_was_read) Run say.sh and post what it printed."
}

# A worker told only that a marker is missing re-renders a body that already had one. Naming the
# file the guard opened is the difference between fixing the body and fixing the path.
what_was_read() {
    [ -n "$unread" ] || { printf 'This command carries no seam marker.'; return; }

    printf 'No seam marker in [%s], the file this command names.' "$unread"
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
# The call is JSON, so a quote the caller typed arrives as an escaped one. Flattening the quote
# and leaving its backslash resolved `--body-file \"path\"` to a file named `\` — the
# guard refusing the comment it had just been handed correctly.
unescaped() { printf '%s' "$1" | sed 's/\\"/"/g'; }

carries_the_marker() {
    case $1 in *'<!-- seam:'*' -->'*) return 0 ;; esac

    # Shell, never a regex. A `sed` backreference is the one line here that a copy through another
    # tool has already silently broken, twice.
    #
    # The quote goes first, turned into a space, so no pattern below has to contain one.
    said=$(unescaped "$1" | tr '"' ' ')

    # `-F` is `--body-file`, and `carries_no_body` above already counts it. Reading only the long
    # form here denied a correctly rendered comment posted the short way — the guard refusing the
    # thing it exists to permit.
    said=$(printf '%s' "$said" | sed 's/ -F / --body-file /')

    named=${said#*--body-file}

    # Here, never after the strips below. Compared at the end it read the first field of the
    # call instead, so a command naming no file at all was refused for the wrong reason.
    [ "$named" != "$said" ] || return 1

    named=${named#=}

    # Every leading space, never one. The quote above became a space, so `--body-file "path"` leaves
    # two and a single strip left an empty first field — the guard then denied a comment it had just
    # resolved the path for.
    while :; do
        case $named in ' '*) named=${named# } ;; *) break ;; esac
    done

    named=${named%% *}

    [ -n "$named" ] || return 1

    unread=$named
    grep -q '<!-- seam:' "$named" 2>/dev/null
}

# The reason names a path now, and a Windows path is backslashes. Unescaped, one of them ends the
# JSON string early and the harness reads no decision at all — which is an allow, silently.
as_json() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

deny() {
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny",'
    printf '"permissionDecisionReason":"%s"}}
' "$(as_json "$1")"
    exit 0
}

allow() { exit 0; }

main "$@"
