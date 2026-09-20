#!/bin/sh
#
# Deny a restore that would throw away work nothing has kept.
#
# Reads a `PreToolUse` tool call as JSON on stdin. Denies a `Bash` command running
# `git checkout -- <path>` or `git restore <path>` when a named path carries changes no commit,
# index or stash holds.
#
# **`git checkout --` restores to `HEAD`, never to the state before the last edit.** A worker
# plants a break to prove a check goes red, then restores — and the restore takes the repair it was
# testing along with the break.
#
# It happened twice on 20 September 2026, hours apart, in one session. The second time the file
# held a widened guard and four new cases; all of it went, and `grep -c` on the function name
# answered `0`. Both were rewritten from memory.
#
# **Knowing this is not enough, which is the whole reason it is a hook.** It sat in that worker's
# own recorded lessons the first time it happened.
#
# **This is lint, and calling it anything stronger would be a lie.** The worker holds the same disk
# and can edit this file. It closes the easy path, and `closes.sh` carries the same limit.
#
# Exit 0 always. A hook that fails must not become a hook that blocks everything.

set -u

main() {
    call=$(cat)

    command=$(command_in "$call")
    [ -n "$command" ] || allow

    paths=$(paths_a_restore_would_take "$command")
    [ -n "$paths" ] || allow

    losing=$(what_no_commit_holds $paths)
    [ -n "$losing" ] || allow

    refuse_the_restore "$losing"
}

# The `Bash` command, or nothing. A tool call of another kind is not this hook's subject.
command_in() {
    printf '%s' "$1" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -1
}

#
# **Both spellings, because git ships two.** `git checkout -- <path>` is the old one and
# `git restore <path>` the new, and a worker reaching for either means the same thing.
#
# `--staged` and `--source` are left alone: the first moves the index and the second is a
# deliberate read from elsewhere. Neither is the accident this refuses.
paths_a_restore_would_take() {
    case $1 in
        *--staged*|*--source*|*--worktree\ --staged*) return 0 ;;
        *git\ checkout\ --\ *)  after 'git checkout -- ' "$1" ;;
        *git\ restore\ *)       after 'git restore ' "$1" ;;
        *) return 0 ;;
    esac
}

# Everything after the verb, up to the next chained command. A `&&` past the paths belongs to
# whatever runs next, and reading it would ask git about a word.
after() {
    printf '%s' "${2#*$1}" | sed 's/[;&|].*//' | tr -s ' '
}

#
# The named paths that differ from `HEAD` and are in no stash.
#
# **The index is not safety.** A staged change is still lost by `git checkout --`, so it counts as
# work to lose rather than work that is held.
what_no_commit_holds() {
    for path in "$@"; do
        case $path in -*) continue ;; esac

        changed=$(git diff HEAD --numstat -- "$path" 2>/dev/null | grep -c .)
        [ "$changed" -gt 0 ] 2>/dev/null || continue

        held_in_a_stash "$path" && continue

        printf '%s ' "$path"
    done
}

#
# A stash holding the same path means a copy survives the restore. It is not the same content, and
# saying so is the caller's job rather than this one's.
#
# **No stash at all is not a stash holding everything.** A `while` on the right of a pipe runs zero
# times over an empty list, the pipeline exits 0, and reading that status answered *held* for every
# path on a repository that had never stashed. Every deny in the suite went silent on it.
held_in_a_stash() {
    entries=$(git stash list --format=%gd 2>/dev/null) || return 1
    [ -n "$entries" ] || return 1

    for entry in $entries; do
        git diff --name-only "$entry^" "$entry" 2>/dev/null | grep -qxF "$1" && return 0
    done

    return 1
}

refuse_the_restore() {
    deny "this restore would take uncommitted work in [$1] back to HEAD, and no commit or stash holds it. git checkout -- restores to HEAD, never to the edit before yours. Commit or stash first, then restore."
}

deny() {
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny",'
    printf '"permissionDecisionReason":"%s"}}\n' "$1"

    exit 0
}

allow() { exit 0; }

main "$@"
