#!/bin/sh
#
# A work source that is GitHub Issues. **The first adapter, and not the model.**
#
# Needs `gh`, which floor does not declare — so floor reaches this only where the remote is GitHub
# *and* `gh` is there, and `source-dir.sh` answers otherwise. §3's level 1, both halves.
#
# A question is a comment; its answer is what people wrote after it. The human is asked where they
# already are, and one marker line addresses one question among many:
#
#     floor-question: <question> <digest of the words>
#
# **The marker carries a digest, not the words.** Asking twice with the same words is one question
# and different words are refused, and comparing them means recovering the first ones out of a
# transcript GitHub formats however it likes. A digest needs no recovery and no parser.
#
# **Only the question is marked.** An answer is whatever a person wrote next — a marker they have to
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

# The issue's own words, and no interpretation of them. A transport carries; it does not read.
read_item() {
    gh issue view "$1" --json title,body --jq '.title, "", .body' || return 1
}

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
# What GitHub says it already has, or nothing — and the two are told apart.
#
# A search that failed used to return empty, which `publish_delivery` reads as *no delivery yet* and
# answers by opening one. A resumed run whose lookup hit a network, a token or a rate limit published
# a second delivery for work that already had one.
#
# Captured before the pipe: a pipeline reports its last stage, and `head` succeeds on nothing at all.
#
delivery_of() {
    found=$(gh pr list --state all --search "$1 in:body" --json headRefName,url \
                --jq '.[] | .headRefName + " " + .url' 2>&1) || {
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
    asked=$(after_marker "$1" "floor-question: $2 ")
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
    said=$(said_after "$1" "floor-question: $2 ")
    [ -n "$said" ] || return 1
    printf '%s\n' "$said"
}

#
# What people said after this question, and never another question.
#
# `gh` lays each comment out as its metadata, a rule, then its body. So the marker is followed by the
# rest of the ask, which names the clause — reading from there would authorise it with itself.
#
# Questions bound this at both ends. One is asked per unauthorised clause, so several stand open at
# once, and the next one beginning means this one was passed over rather than answered.
#
said_after() {
    gh issue view "$1" --comments 2>/dev/null \
        | awk -v mark="$2" '
            /^floor-question: / { mine = index($0, mark) > 0; want = 0; next }
            !mine               { next }
            /^author:/          { meta = 1; next }
            meta && $0 == "--"  { meta = 0; want = 1; next }
            meta                { next }
            $0 == "--"          { next }
            want && NF          { print }'
}

# The words after a marker, in the first comment carrying it. One pass over the transcript, so
# nothing here depends on how GitHub lays a comment out.
after_marker() {
    gh issue view "$1" --comments 2>/dev/null \
        | awk -v mark="$2" 'index($0, mark) { print substr($0, index($0, mark) + length(mark)); exit }'
}

# 32 bits, so two texts can share one. A collision lets a rewritten question pass for the one already
# asked — the cost is a human holding words that changed, never a bar that moved.
digest() { printf '%s' "$1" | cksum | awk '{ print $1 }'; }

case "${1:-}" in
    read)    shift; read_item        "${1:-}" ;;
    publish) shift; publish_delivery "${1:-}" "${2:-}" "${3:-}" "${4:-}" ;;
    ask)     shift; put_question     "${1:-}" "${2:-}" "${3:-}" ;;
    receive) shift; read_answer      "${1:-}" "${2:-}" ;;
    *)       echo "source-github: read <issue> | publish <issue> <run> <branch> <title> | ask <issue> <question> <text> | receive <issue> <question>" >&2
             exit 2 ;;
esac
