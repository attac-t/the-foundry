#!/bin/sh
#
# A work source that is a directory of files. The second adapter, and the reason the first one is
# not the model.
#
# `sh` only — no `gh`, no network, no parser. Floor declares `sh`, `awk` and `git`, so this is the
# adapter that can always answer, and GitHub is the conditional one.
#
# Every path here is a plain file, so a person reads a question with an editor and answers it by
# writing one. That is the whole of the ask channel: no terminal, no daemon, no inbox.
#
#     items/<item>                   what someone wants
#     claims/<item>/held             which host took it, and when
#     deliveries/<run>               what one run published
#     questions/<item>/<question>    what a run asked
#     answers/<item>/<question>      what a human answered
#
# Usage: sh source-dir.sh read    <item>
#        sh source-dir.sh publish <item> <run> <branch> <title> [word] [brief]
#        sh source-dir.sh ask     <item> <question> <text>
#        sh source-dir.sh receive <item> <question>
#
# Exit: 0 answered · 1 nothing there · 2 asked for something this does not do · 3 it could not
#       read or write what it needs · 4 this run already sent something else under that name
#

set -u

# Floor's home holds floor's things, so a directory source needs no configuration to be found —
# §3's level 1. Read from the environment rather than from floor: an adapter that has to import its
# caller is not one you can replace.
root=${FOUNDRY_SOURCE_DIR:-${FOUNDRY_HOME:-${HOME:-.}/.foundry}/source}

# What someone wants, as they wrote it. Absent is an answer and empty is a different one —
# a file that is there and cannot be read is neither, and `cat` failing after
# `[ -f ]` passed reported it as the first.
read_item() {
    [ -f "$root/items/$1" ] || return 1
    [ -r "$root/items/$1" ] || return 3

    cat "$root/items/$1"
}

# What one run published, and the identity of it. Keyed by the run and never by the item, because
# one item has many runs and each delivers its own. Resuming asks again and gets the
# same identity back; a different branch is refused rather than absorbed.
publish_delivery() {
    file="$root/deliveries/$2"

    [ -f "$file" ] || record_delivery "$file" "$3" "$1" "$4" || return 3
    [ -r "$file" ] || return 3
    delivered "$file" "$3" || return 4

    keep_the_brief "$2" "${6:-}"
    printf '%s\n' "$file"
}

# Beside the record, never inside it. The first line of a delivery is three
# fields a machine splits on tabs, and a body is many lines with tabs
# of its own — one file holding both is a parser nobody wrote.
#
# A second run over the same delivery leaves the first brief alone. The
# record already refuses any changed branch, and a body that is then
# rewritten under a reader is the very same drift all over again.
keep_the_brief() {
    [ -n "$2" ] && [ -r "$2" ] || return 0

    said="$root/deliveries/$1.brief"
    [ -f "$said" ] && return 0

    cat "$2" > "$said" || return 3
}

record_delivery() {
    mkdir -p "$root/deliveries" || return 3
    printf '%s\t%s\t%s\n' "$2" "$3" "$4" > "$1" || return 3
}

# Whether the delivery on disk carries the branch being published. Asked of a fresh write too, so
# what is answered with is what landed rather than what was meant to.
delivered() { [ "$(awk 'NR == 1 { print $1 }' "$1")" = "$2" ]; }

# Put a question where the human already is, once. A resumed run derives the same identity
# and asks again with the same words, and that stays one question. Different words
# under one identity are refused: someone may be holding the first.
put_question() {
    file="$root/questions/$1/$2"

    [ -f "$file" ] || record_question "$1" "$file" "$3" || return 3
    [ -r "$file" ] || return 3
    same_question "$file" "$3" || return 4
}

record_question() {
    mkdir -p "$root/questions/$1" || return 3
    printf '%s\n' "$3" > "$2" || return 3
}

same_question() { [ "$(cat "$1")" = "$2" ]; }

# A human's answer, as they left it. Nothing here reads it — what an answer means belongs
# to whoever asked, and a transport that decided would answer for them. One that
# cannot be read is not a human who has not replied.
read_answer() {
    [ -f "$root/answers/$1/$2" ] || return 1
    [ -r "$root/answers/$1/$2" ] || return 3

    cat "$root/answers/$1/$2"
}

#
# What the source says this work is. A directory has no labels, so a field carries it — and the same
# word reaches core either way, which is the seam this exists to prove.
#
# Frontmatter only. A `kind:` further down the file is the item's prose, and reading it would make a
# sentence into a classification.
#
kind_of_item() {
    [ -f "$root/items/$1" ] || return 1
    [ -r "$root/items/$1" ] || return 3

    awk 'NR == 1 && $0 != "---" { exit }
         NR > 1  && $0 == "---" { exit }
         $1 == "kind:" { for (i = 2; i <= NF; i++) print $i }' "$root/items/$1"
}


#
# Every delivery this directory holds but this run's. Nothing here merges, so
# it holds no notion of open and reports every delivery it recorded.
open_deliveries() {
    [ -d "$root/deliveries" ] || return 0

    for file in "$root/deliveries"/*; do
        [ -f "$file" ] || continue

        branch=$(awk 'NR == 1 { print $1 }' "$file")
        [ -n "$branch" ] || continue
        [ "$branch" = "$1" ] && continue

        printf '%s\t%s\n' "$branch" "$file"
    done
}


# `mkdir` is the compare-and-swap, and it fails when the claim is there. The
# holder rewriting its own stamp is the renewal, so nothing slips between.
take_claim() {
    mkdir -p "$root/claims" 2>/dev/null || return 3
    mkdir "$root/claims/$1" 2>/dev/null || held_by "$1" "$2" || return 4

    stamp_claim "$root/claims/$1/held" "$2"
}

# The epoch is what makes an age arithmetic. The stamp beside it is for whoever reads the file, and
# the two are written together so they cannot disagree.
stamp_claim() {
    printf '%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$2" "$(date -u +%s)" > "$1" || return 3
}

held_by() {
    held=$(read_claim "$1") || return 1

    rest=${held#*	}
    [ "${rest%%	*}" = "$2" ]
}

# Who holds it, and since when. Nothing when nobody does.
read_claim() {
    [ -f "$root/claims/$1/held" ] || return 1

    cat "$root/claims/$1/held"
}

# Only the holder may let go. A host dropping another's claim is the race this exists to stop,
# arriving one step later.
drop_claim() {
    held_by "$1" "$2" || return 4

    rm -rf "$root/claims/$1"
}

case "${1:-}" in
    read)    shift; read_item        "${1:-}" ;;
    kind)    shift; kind_of_item     "${1:-}" ;;
    open)    shift; open_deliveries  "${1:-}" ;;
    claim)   shift; take_claim       "${1:-}" "${2:-}" ;;
    held)    shift; read_claim       "${1:-}" ;;
    release) shift; drop_claim       "${1:-}" "${2:-}" ;;
    publish) shift; publish_delivery "${1:-}" "${2:-}" "${3:-}" "${4:-}" "${5:-}" "${6:-}" ;;
    ask)     shift; put_question     "${1:-}" "${2:-}" "${3:-}" ;;
    receive) shift; read_answer      "${1:-}" "${2:-}" ;;
    *)       echo "source-dir: read <item> | claim <item> <host> | held <item> | release <item> <host> | publish <item> <run> <branch> <title> [word] [brief] | ask <item> <question> <text> | receive <item> <question>" >&2
             exit 2 ;;
esac
