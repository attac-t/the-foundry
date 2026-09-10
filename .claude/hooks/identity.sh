#!/bin/sh
#
# Deny a forge write when the signed-in account is not the one this repository expects.
#
# **The active account changes without a word.** Four times in one session, none announced, none
# caused by the session. Three writes were refused by the other account's own permissions and one
# landed — a finding published on a public thread under a name that did not write it.
#
# `.claude/rules/identity.md` says a wrong author cannot be fixed. A comment can be deleted and
# reposted; a commit cannot be moved by any forge in use, and eighty-one here carry the wrong one
# for good.
#
# **A check at session start does not hold.** Each switch followed a clean check by under an hour,
# so the answer has to be taken at the write rather than remembered from before it.
#
# Who is expected comes from the environment first and the origin remote second — never a name in
# this file. `FOUNDRY_FORGE` names it outright; without that, the owner in `origin` is the ordinary
# answer, and a fork contributor sets the variable.
#
# **This is lint, and calling it anything stronger would be a lie.** The worker holds the same
# account and the same disk, and can edit this file. It closes the easy path. #419 owns the control
# that binds, and `seam.sh` says the same about itself for the same reason.
#
# Reads a `PreToolUse` tool call as JSON on stdin.
#
# Exit 0 always. A hook that fails must not become a hook that blocks everything.

set -u

main() {
    call=$(cat)

    writes_to_the_forge "$call" || allow

    wanted=$(account_this_repository_expects) || allow
    [ -n "$wanted" ] || allow

    signed_in=$(account_signed_in) || allow
    [ "$signed_in" = "$wanted" ] && allow

    deny "the forge is signed in as $signed_in and this repository expects $wanted. A wrong author cannot be fixed — identity.md. Run gh auth switch, then repeat the command."
}

# A command that creates or changes something on the forge. A read costs nothing and is left alone,
# because a guard that stops reading is one people turn off.
writes_to_the_forge() {
    case $1 in
        *'gh pr create'*|*'gh pr merge'*|*'gh pr edit'*|*'gh pr comment'*|*'gh pr review'*) return 0 ;;
        *'gh issue create'*|*'gh issue edit'*|*'gh issue comment'*|*'gh issue close'*)      return 0 ;;
        *'gh release'*|*'gh api'*' -X '*|*'gh api --method'*|*'git push'*)                  return 0 ;;
    esac

    return 1
}

# Named outright, or the owner `origin` points at. Never a name written here — this file ships in a
# repository that is not the only one it will sit in.
account_this_repository_expects() {
    [ -n "${FOUNDRY_FORGE:-}" ] && { printf '%s' "$FOUNDRY_FORGE"; return 0; }

    owner_in_origin
}

# `github.com/<owner>/<repo>`, in either spelling `git remote` hands back.
owner_in_origin() {
    said=$(git remote get-url origin 2>/dev/null) || return 1

    printf '%s' "$said" | sed -n 's#^.*[:/]\([^/:]*\)/[^/]*$#\1#p'
}

account_signed_in() { gh api user --jq .login 2>/dev/null; }

deny() {
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny",'
    printf '"permissionDecisionReason":"%s"}}\n' "$1"
    exit 0
}

allow() { exit 0; }

main "$@"
