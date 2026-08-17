#!/bin/sh
#
# A work source that is a directory of files. **The second adapter, and the reason the first one is
# not the model.**
#
# `sh` only — no `gh`, no network, no parser. Floor declares `sh`, `awk` and `git`, so this is the
# adapter that can always answer, and GitHub is the conditional one.
#
# Every path here is a plain file, so a person reads a question with an editor and answers it by
# writing one. That is the whole of the ask channel: no terminal, no daemon, no inbox.
#
#     items/<item>                   what someone wants
#     deliveries/<run>               what one run published
#     questions/<item>/<question>    what a run asked
#     answers/<item>/<question>      what a human answered
#
# Usage: sh source-dir.sh read    <item>
#        sh source-dir.sh publish <item> <run> <branch> <title>
#        sh source-dir.sh ask     <item> <question> <text>
#        sh source-dir.sh receive <item> <question>
#
# Exit: 0 answered · 1 nothing there · 2 asked for something this does not do · 3 cannot write
#       4 this run already sent something else under that name
#

set -u

# Floor's home holds floor's things, so a directory source needs no configuration to be found —
# §3's level 1. Read from the environment rather than from floor: an adapter that has to import its
# caller is not one you can replace.
root=${FOUNDRY_SOURCE_DIR:-${FOUNDRY_HOME:-${HOME:-.}/.foundry}/source}

# What someone wants, as they wrote it. Absent is an answer, and a different one from empty.
read_item() {
    [ -f "$root/items/$1" ] || return 1
    cat "$root/items/$1"
}

#
# What one run published, and the identity of it.
#
# **Keyed by the run, never by the item.** One item has many runs and each delivers its own, so an
# item-keyed delivery would hand the second run the first one's answer.
#
# Resuming asks again and gets the same identity back. **A different branch is refused, not
# absorbed** — returning the first delivery there would answer a question nobody asked.
#
publish_delivery() {
    file="$root/deliveries/$2"

    [ -f "$file" ] || record_delivery "$file" "$3" "$1" "$4" || return 3
    delivered "$file" "$3" || return 4

    printf '%s\n' "$file"
}

record_delivery() {
    mkdir -p "$root/deliveries" || return 3
    printf '%s\t%s\t%s\n' "$2" "$3" "$4" > "$1" || return 3
}

# Whether the delivery on disk carries the branch being published. Asked of a fresh write too, so
# what is answered with is what landed rather than what was meant to.
delivered() { [ "$(awk 'NR == 1 { print $1 }' "$1")" = "$2" ]; }

#
# Put a question where the human already is, once.
#
# A resumed run derives the same identity and asks again with the same words, and that must stay one
# question. **Different words under one identity are refused**: someone may be holding the first, and
# rewriting it under them is not a resume.
#
put_question() {
    file="$root/questions/$1/$2"

    [ -f "$file" ] || record_question "$1" "$file" "$3" || return 3
    same_question "$file" "$3" || return 4
}

record_question() {
    mkdir -p "$root/questions/$1" || return 3
    printf '%s\n' "$3" > "$2" || return 3
}

same_question() { [ "$(cat "$1")" = "$2" ]; }

# A human's answer, as they left it. Nothing here reads it — what an answer means belongs to whoever
# asked, and a transport that decided would be answering for them.
read_answer() {
    [ -f "$root/answers/$1/$2" ] || return 1
    cat "$root/answers/$1/$2"
}

case "${1:-}" in
    read)    shift; read_item        "${1:-}" ;;
    publish) shift; publish_delivery "${1:-}" "${2:-}" "${3:-}" "${4:-}" ;;
    ask)     shift; put_question     "${1:-}" "${2:-}" "${3:-}" ;;
    receive) shift; read_answer      "${1:-}" "${2:-}" ;;
    *)       echo "source-dir: read <item> | publish <item> <run> <branch> <title> | ask <item> <question> <text> | receive <item> <question>" >&2
             exit 2 ;;
esac
