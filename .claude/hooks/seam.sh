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

deny() {
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny",'
    printf '"permissionDecisionReason":"%s"}}\n' "$1"
    exit 0
}

allow() { exit 0; }

call=$(cat)

# `gh pr comment`, `gh issue comment`, and the two API paths that reach the same place.
writes_a_comment() {
    case $1 in
        *'gh pr comment'*|*'gh issue comment'*|*'gh pr review'*) return 0 ;;
        *'issues/'*'/comments'*|*'pulls/'*'/comments'*)          return 0 ;;
    esac
    return 1
}

carries_the_marker() { case $1 in *'seam:'*) return 0 ;; esac; return 1; }

writes_a_comment "$call" || allow
carries_the_marker "$call" && allow

deny "a public comment is rendered by plugins/floor/bin/say.sh, which takes fields and refuses seven ways. This command carries no seam marker. Run say.sh and post what it printed."
