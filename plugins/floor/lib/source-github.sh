#!/bin/sh
#
# A work source that is GitHub Issues. The first adapter, and not the model.
#
# Needs `gh`, which floor does not declare — so floor reaches this only where the remote is GitHub
# *and* `gh` is there, and `source-dir.sh` answers otherwise. §3's level 1, both halves.
#
# A question is a comment; its answer is what people wrote after it. The human is asked where they
# already are, and one marker line addresses one question among many:
#
#     floor-question: <question> <digest of the words>
#
# The marker carries a digest, not the words. Asking twice with the same words is one question
# and different words are refused, and comparing them means recovering the first ones out of a
# transcript GitHub formats however it likes. A digest needs no recovery and no parser.
#
# Only the question is marked. An answer is whatever a person wrote next — a marker they have to
# type is a command language, and the first person who met one answered and went unheard.
#
# Usage: sh source-github.sh read    <issue>
#        sh source-github.sh publish <issue> <run> <branch> <title>
#        sh source-github.sh ask     <issue> <question> <text>
#        sh source-github.sh receive <issue> <question>
#
# Exit: 0 answered · 1 nothing there · 2 asked for something this does not do · 3 GitHub refused
#       4 this run already sent something else under that name
#

set -u

command -v gh >/dev/null 2>&1 || { echo "source-github: gh is not here" >&2; exit 2; }

#
# The issue's own words, and no interpretation of them. A transport carries; it does not read.
#
# A source that could not be asked is not an item that is not there. `gh` exits 1 for both, so its
# message is not what tells them apart. A second question is: a repository cannot be absent and an
# issue can — measured, bad credentials fail both, and a missing issue fails only the first.
#
# One case survives this and is not caught: a token that reads the repository and not its issues
# probes as reachable, and answers *nothing there* wrongly.
#
read_item() {
    gh issue view "$1" --json title,body --jq '.title, "", .body' && return 0

    repository_answers || return 3
    return 1
}

# Something that cannot be absent, asked only when the item could not be read.
repository_answers() { gh repo view --json name >/dev/null 2>&1; }

#
# What one run published, and the identity of it.
#
# GitHub keys a pull request on its head branch and knows nothing of runs, so the body carries the
# run and a search finds it. Keying on the branch instead would let one run open a second delivery
# by publishing a second branch, which is the case a resume must never look like.
#
publish_delivery() {
    had=$(delivery_of "$2") || return 3

    [ -z "$had" ] && { open_delivery "$1" "$2" "$3" "$4"; return $?; }

    # `<branch> <url>`, and a branch holds no space.
    [ "${had% *}" = "$3" ] || return 4
    printf '%s\n' "${had##* }"
}

#
# What GitHub says it already has, or nothing, and the two are told apart. A search that
# failed used to return empty, which reads as no delivery yet and answers by
# opening a second one for work that already had one.
#
# GitHub matches words in a body and not substrings, so two runs made the same day share three
# tokens of four and each other's pull requests come back. The search narrows;
# the marker floor wrote is what decides. Named, so the `gh` line holds no pipe.
delivery_of() {
    shape=".[] | select(.body | contains(\"floor-run: $1\")) | .headRefName + \" \" + .url"

    found=$(gh pr list --state all --search "$1 in:body" --json headRefName,url,body --jq "$shape" 2>&1) || {
        printf 'source-github: could not ask what is already delivered: %s\n' "$found" >&2
        return 3
    }

    printf '%s\n' "$found" | head -1
}

# `Closes #<issue>` makes the delivery answer the item. `floor-run` is what makes it this run's.
open_delivery() {
    gh pr create --head "$3" --title "$4" --body "Closes #$1

floor-run: $2" || return 3
}

put_question() {
    asked=$(after_marker "$1" "floor-question: $2 ") || return 3
    said=$(digest "$3")

    [ -z "$asked" ] && { post_question "$1" "$2" "$said" "$3"; return $?; }

    [ "$asked" = "$said" ] || return 4
}

post_question() {
    gh issue comment "$1" --body "floor-question: $2 $3

$4" >/dev/null || return 3
}

#
# A human's answer, as they wrote it. Nothing here reads it — what an answer means belongs to whoever
# asked, and a transport that decided would be answering for them.
#
read_answer() {
    said=$(said_after "$1" "floor-question: $2 ") || return 3
    [ -n "$said" ] || return 1

    printf '%s\n' "$said"
}


#
# Every comment on the item, as bodies, with a boundary this file chose.
#
# `--comments` is `gh`'s human transcript, and a layout is not a contract. It changes without
# notice, and on a client old enough for GitHub to reject its GraphQL it stopped being fetchable at
# all — `projectCards`, which nothing here asked for. `--json comments` returns the field on every
# client tested, and `--jq` is `gh`'s own, so this declares no parser.
#
# A body holding a line that is exactly the boundary spoofs one. The transcript had the same
# exposure through `author:` and its rule line; the difference is that this line is ours to change.
#
# Captured before it is handed anywhere: a pipeline reports its last stage, and `awk` succeeds on
# nothing at all.
#
comments_of() {
    # The `|` here is jq's, not the shell's — named so the line that runs `gh` holds no pipe at all,
    # which is the only thing `bin/shell.sh` can tell apart without a parser.
    shape='.comments[] | "floor-comment:", .body'

    seen=$(gh issue view "$1" --json comments --jq "$shape" 2>&1) || {
        printf 'source-github: could not read the comments: %s\n' "$seen" >&2
        return 3
    }

    printf '%s\n' "$seen"
}

#
# The words after a marker, in the first comment carrying it. No boundary is needed — the first line
# holding the mark is the one.
#
# A read that failed is not a question nobody asked. Empty is what `put_question` reads as *not
# asked yet*, and it answers by asking — so a resumed run whose lookup hit a network put the question
# to the human twice.
#
after_marker() {
    seen=$(comments_of "$1") || return 3

    printf '%s\n' "$seen" \
        | awk -v mark="$2" 'index($0, mark) { print substr($0, index($0, mark) + length(mark)); exit }'
}

#
# What people said after this question, and never another question.
#
# The marked comment holds the ask, so its own body is skipped — reading it would authorise a clause
# with the words that asked about it. The answer is whatever the next comment says.
#
# Questions bound this at both ends. One is asked per unauthorised clause, so several stand open at
# once, and the next one beginning means this one was passed over rather than answered.
#
said_after() {
    seen=$(comments_of "$1") || return 3

    printf '%s\n' "$seen" \
        | awk -v mark="$2" '
            $0 == "floor-comment:" { want = want || mine; mine = 0; next }
            /^floor-question: /    { mine = index($0, mark) > 0; want = 0; next }
            want && NF             { print }'
}

# 32 bits, so two texts can share one. A collision lets a rewritten question pass for the one already
# asked — the cost is a human holding words that changed, never a bar that moved.
digest() { printf '%s' "$1" | cksum | awk '{ print $1 }'; }

#
# What the source says about one run's delivery: `<head> <state> <mergeable> <checks>`.
#
# **Four questions in one call, because four calls are four moments.** A head that moves between them
# is the case a merge exists to refuse, and asking twice is how it slips through.
#
# `headRefOid` and not the branch name. A branch is a pointer a push moves; the caller compares a
# commit against the one its evidence names, and only a commit answers that.
#
# `NONE` when the source requires no check, told apart from a check that has not answered. A source
# that runs nothing is not a source that is still thinking.
#
delivery_state() {
    had=$(delivery_of "$1") || return 3
    [ -n "$had" ] || return 1

    shape='.headRefOid + " " + .state + " " + (.mergeable // "UNKNOWN") + " "
           + ([.statusCheckRollup[]? | (.conclusion // .state // "PENDING")]
              | if length == 0 then "NONE" else join(",") end)'

    said=$(gh pr view "${had##* }" --json headRefOid,state,mergeable,statusCheckRollup \
               --jq "$shape" 2>&1) || {
        printf 'source-github: could not ask about the delivery: %s\n' "$said" >&2
        return 3
    }

    printf '%s\n' "$said"
}

# `--merge`, never `--squash`. The delivery is the run's own history, and a squash throws away every
# commit the evidence was recorded against.
land_delivery() {
    had=$(delivery_of "$1") || return 3
    [ -n "$had" ] || return 1

    why=$(gh pr merge "${had##* }" --merge 2>&1) && return 0

    printf 'source-github: the merge was refused: %s\n' "$why" >&2
    return 3
}

#
# What the source says this work is. **The only place `foundry:` exists.**
#
# A repository Foundry does not own already has `bug`, `enhancement`, `blocked`. Reinterpreting those
# makes a stranger's vocabulary into Foundry's authority, so a namespace is what keeps them apart —
# `foundry:*` is Foundry's, everything else is the repository's, and nothing crosses.
#
# Core is told `defect`. How a source spells it is the adapter's, and that is the whole of the seam.
#
kind_of_item() {
    said=$(gh issue view "$1" --json labels --jq '.labels[].name' 2>&1) || {
        repository_answers || return 3
        return 1
    }

    printf '%s\n' "$said" | awk '/^foundry:/ { sub(/^foundry:/, ""); print }'
}

case "${1:-}" in
    read)    shift; read_item        "${1:-}" ;;
    kind)    shift; kind_of_item     "${1:-}" ;;
    publish) shift; publish_delivery "${1:-}" "${2:-}" "${3:-}" "${4:-}" ;;
    ask)     shift; put_question     "${1:-}" "${2:-}" "${3:-}" ;;
    receive) shift; read_answer      "${1:-}" "${2:-}" ;;
    state)   shift; delivery_state   "${1:-}" ;;
    land)    shift; land_delivery    "${1:-}" ;;
    *)       echo "source-github: read <issue> | kind <issue> | publish <issue> <run> <branch> <title> | ask <issue> <question> <text> | receive <issue> <question> | state <run> | land <run>" >&2
             exit 2 ;;
esac
