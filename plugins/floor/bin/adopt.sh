#!/bin/sh
#
# Write this repository's judged declaration, and move its pin when the plugin ships new content.
#
# **The only thing floor ships that writes to a repository.** `join.sh` joins a host, and its header
# promises it writes nothing here. `run.sh` runs one attempt at one item. Neither subject is the
# repository itself, and this one's is — so it is a third script rather than a verb bolted onto
# either.
#
# **A working tree change and nothing else.** Nothing is staged, nothing is committed and nothing is
# pushed. A pin that moves without somebody reading it is the fault the digest exists to stop, so
# the command writes and a person commits.
#
# **Only ever a digest.** `git hash-object --no-filters`, which is the same answer floor computes
# when it decides whether the adapter about to judge a run is the one the repository authorised. A
# tag, a version and a range each read as a yes while the thing they name moves underneath.
#
#   sh adopt.sh adopt <judge> <adapter>   say how one judge is reached, and pin what is here
#   sh adopt.sh upgrade                   move every pin to the content this plugin ships now
#
# **A reach whose transport is not `@adapter` is never touched.** A repository's own command is its
# own business, and no digest here answers for one.
#
# A run may not do either of these. The declaration is pinned to the base like every other source a
# bar comes from, so a run that edited it is refused at 7 before any judge is asked. That guard is
# `run.sh`'s, and this deliberately adds no second copy of it.
#
# Two voices: `say` is the report, and `note` is a refusal on stderr, where a redirected run still
# shows one.
#
# No `set -e`: `upgrade` reads every reach, and one it cannot move must not hide the next.
#
# Exit: 0 the declaration names what this plugin ships, 1 something must be settled first,
#       2 asked for something this does not do, 3 no repository, or the declaration cannot be read

set -u

SELF_DIR=$(cd "$(dirname "$0")" && pwd)
PLUGIN_ROOT=$(cd "$SELF_DIR/.." 2>/dev/null && pwd)

# Where the declaration is, once a repository has been found. `name_the_declaration` sets both.
DECLARED=
DECLARED_DIR=

# What `upgrade` found. `PENDING` is the `line digest` pairs the rewrite applies, and the two
# tallies are what the verdict reads.
PENDING=
MOVED=0
LEFT=0

# Outside the repository, so a killed run leaves no file nobody asked for. **It does not make the
# write atomic.** The copy back truncates the declaration and fills it, and a run killed inside that
# window leaves a short file. Naming the window beats promising what the mechanism does not give.
#
# `mktemp` is not POSIX and floor declares `sh`, `git` and `awk` — the same reason `run.sh` gives.
WORK=${TMPDIR:-/tmp}/floor-adopt-$$
trap 'rm -rf "$WORK"' EXIT

main() {
    refuse_without_a_repository
    name_the_declaration
    refuse_the_repository_that_ships_the_adapter "$@"
    refuse_a_declaration_holding_carriage_returns

    case "${1:-}" in
        adopt)   shift; adopt "$@" ;;
        upgrade) shift; upgrade "$@" ;;
        *)       usage; exit 2 ;;
    esac
}

usage() {
    say "adopt.sh — write this repository's judged declaration, and move its pin when floor ships new content."
    say ""
    say "  sh adopt.sh adopt <judge> <adapter>   say how one judge is reached, and pin what is here"
    say "  sh adopt.sh upgrade                   move every pin to the content this plugin ships now"
    say ""
    say "A judge is one word — a model at a bench, written <model>:<role>."
    say "This plugin ships: $(adapters_on_one_line)"
    say ""
    say "It writes a working tree change. Nothing is staged, committed or pushed."
}

refuse_without_a_repository() {
    git rev-parse --show-toplevel >/dev/null 2>&1 && return 0

    note "there is no repository here. Run this inside the one that is adopting a judge."
    exit 3
}

# Taken once, from the working tree's own root. A command run three directories down writes the same
# file as one run at the top.
name_the_declaration() {
    TOP=$(git rev-parse --show-toplevel)
    DECLARED_DIR=$TOP/.foundry
    DECLARED=$DECLARED_DIR/judged
}

#
# The repository written to is the working directory's, and nothing in the command says which one
# that is. Floor's own README said to change into the plugin directory first, so a reader who
# followed it word for word declared a judge **in the plugin** and got exit 0. The path inside the
# success line was the only sign.
#
# **A plugin does not adopt through itself.** Refusing where the adapter ships is the whole of the
# fix, because that is the one repository this can never mean.
#
# **Both tops come from `git`, never from `pwd`.** The first cut compared `PLUGIN_ROOT` against the
# top as strings, and on Git Bash one is `C:/Users/…` while the other is `/c/Users/…`. It matched
# nothing and the trap stayed open. Asking git twice gives one form on every platform.
#
# An installed plugin that is no repository makes the first call fail, and that is a pass — it
# cannot be the tree being written to.
#
refuse_the_repository_that_ships_the_adapter() {
    ships=$(git -C "$PLUGIN_ROOT" rev-parse --show-toplevel 2>/dev/null) || return 0
    [ "$ships" = "$TOP" ] || return 0

    note "this would write into $TOP, which is the repository shipping the adapter"
    note "  run it from the repository that is adopting a judge, by its full path:"
    note "    sh $SELF_DIR/adopt.sh $*"
    exit 1
}

# --- adopt ---

#
# One judge, reached through one adapter this plugin ships.
#
# **The clause is not written, and that is deliberate.** A reach says how a judge is asked; a clause
# says what must be judged. `detect-judged.sh` is plain that a repository cannot be guessed into
# wanting a judgement, so this writes the half nobody can type correctly and names the half only a
# person can mean.
#
adopt() {
    [ "$#" -eq 2 ] || { usage; exit 2; }

    refuse_a_judge_name_no_record_can_hold "$1"
    refuse_an_adapter_name_this_cannot_resolve "$2"
    refuse_an_adapter_this_plugin_does_not_ship "$2"
    refuse_a_judge_already_reached "$1"

    digest=$(digest_on_disk "$(adapter_file "$2")")
    refuse_a_digest_git_did_not_give "$2" "$digest"

    ensure_the_declaration_exists
    append_the_reach "$1" "$2" "$digest"
    say_what_only_a_person_can_write "$1"
}

#
# A judge is one word, and never `reach`.
#
# `reach` is the reserved first word that tells the two record kinds apart, so a judge called it is
# read as a reach line whose command is that clause's own prose. The rest of the set is what
# `is_an_adapter_name` refuses for: a name is a word, never a path and never a sentence.
#
refuse_a_judge_name_no_record_can_hold() {
    is_a_judge_name "$1" && return 0

    note "[$1] is not a judge name — letters, digits and : @ . _ - , and never [reach]"
    exit 2
}

is_a_judge_name() {
    case $1 in
        ''|reach|*[!a-zA-Z0-9:@._-]*) return 1 ;;
    esac
    return 0
}

# A name, and a name is one directory. `run.sh` refuses the same set for the same reason: nothing
# here may walk out of the adapters directory or reach a second one sideways.
refuse_an_adapter_name_this_cannot_resolve() {
    is_an_adapter_name "$1" && return 0

    note "[$1] is not an adapter name — lowercase letters, digits and hyphens, and no path in it"
    exit 2
}

is_an_adapter_name() {
    case $1 in
        ''|*[!a-z0-9-]*) return 1 ;;
    esac
    return 0
}

# **Nothing else is asked.** No `$PATH`, no neighbouring install, no repository file — the same one
# path `run.sh` builds, or the pin would authorise a file floor will never reach.
refuse_an_adapter_this_plugin_does_not_ship() {
    ships "$1" && return 0

    note "[$1] is not an adapter this plugin ships, and nothing else answers for it"
    note "  looked at [$(adapter_file "$1")] and nowhere else"
    note "  this plugin ships: $(adapters_on_one_line)"
    exit 1
}

ships() { at=$(adapter_file "$1"); [ -f "$at" ] && [ -r "$at" ]; }

# Overwriting one would move a trust decision somebody already made, silently. `upgrade` moves a pin
# and says both digests; this refuses instead.
refuse_a_judge_already_reached() {
    already_reached "$1" || return 0

    note "[$1] already has a reach in $DECLARED, and nothing here overwrites one"
    note "  its pin moves when the shipped adapter changes: sh adopt.sh upgrade"
    exit 1
}

#
# **A file that cannot be read is not a file with no reach in it.** Reading the failure as *not
# reached* would append a second reach into a declaration nobody can see, which is the thing the
# refusal above exists to stop. `upgrade` already says this about itself.
#
already_reached() {
    [ -e "$DECLARED" ] && [ ! -r "$DECLARED" ] && {
        note "$DECLARED is there and cannot be read, so nothing here may add to it"
        exit 3
    }
    [ -r "$DECLARED" ] || return 1

    awk -v who="$1" '!/^[ \t]*#/ && $1 == "reach" && $2 "" == who "" { found = 1 }
                     END { exit !found }' "$DECLARED"
}

# The guard that makes *only a digest* true by construction rather than by intention. `git` answers
# nothing when it cannot read the file, and an empty pin written here would refuse at 40 forever.
refuse_a_digest_git_did_not_give() {
    is_a_digest "$2" && return 0

    note "git gave no digest for [$(adapter_file "$1")], so there is nothing to pin"
    exit 3
}

#
# The file, when a repository has none.
#
# A header, because a bare reach in an empty file is a record nobody can read back. Four lines and
# no more: what a repository means by a judge is its own, and prose written into somebody's tree is
# prose they did not choose.
#
ensure_the_declaration_exists() {
    [ -e "$DECLARED" ] && return 0

    mkdir -p "$DECLARED_DIR" || fail_unwritable "$DECLARED_DIR"

    printf '%s\n' \
        '# What no command here can answer, and who answers it.' \
        '#' \
        '# `<judge>  <text>` is a clause somebody must answer. `reach  <judge>  @adapter <id> <digest>`' \
        '# says how the runner asks that judge, at exactly the adapter content this repository trusts.' \
        '' > "$DECLARED" || fail_unwritable "$DECLARED"
}

#
# A hand-written file is the one this command exists to replace, and plenty of editors leave the
# last line unterminated. Appending to one glues the reach onto whatever was there — the reader
# then sees a clause whose first word is not `reach`, so the reach is invisible and the clause is
# wrong. It reported success.
#
# `$( )` strips trailing newlines, so a file already ending in one yields the empty string here.
#
ensure_the_last_line_ended() {
    [ -s "$DECLARED" ] || return 0
    [ -n "$(tail -c 1 "$DECLARED")" ] || return 0

    printf '\n' >> "$DECLARED" || fail_unwritable "$DECLARED"
}

# Appended, never inserted. Order means nothing to the reader, and a writer that picks a place in
# somebody else's file is a writer that reformats it.
append_the_reach() {
    ensure_the_last_line_ended

    printf 'reach  %s  @adapter %s %s\n' "$1" "$2" "$3" >> "$DECLARED" || fail_unwritable "$DECLARED"

    say "wrote into $DECLARED:"
    say ""
    say "  reach  $1  @adapter $2 $3"
}

#
# A reach with no clause asks nobody anything.
#
# This has written how a judge is reached and nothing about what it must answer for, so a reader who
# takes the job as finished would find nothing judged and nothing refusing. Said at the prompt
# rather than in a README, which is where the last person to need it was not.
#
say_what_only_a_person_can_write() {
    say ""
    say "That is how [$1] is reached. It does not say what [$1] must answer for."
    say "Add a clause on its own line — the judge, then the sentence a person means by it:"
    say ""
    say "  $1  a change to what a run may claim is read by something that did not write it"
    say ""
    say "Nothing is staged and nothing is committed. Read the change, then commit it."
}

# --- upgrade ---

#
# Every `@adapter` pin, moved to what this plugin ships now.
#
# **Read whole, then written once.** A rewrite per reach would leave a declaration half moved if the
# second one could not be graded, and half a trust decision is the one state nobody can read.
#
upgrade() {
    [ "$#" -eq 0 ] || { usage; exit 2; }

    refuse_a_declaration_this_cannot_upgrade

    reaches=$(adapter_reaches)
    refuse_a_declaration_naming_no_adapter "$reaches"

    grade_each_reach "$reaches"
    move_what_moved
    verdict
}

#
# An absence and a file nobody can read are different findings, and `detect-judged.sh` already draws
# the line between them. One is a repository that has not adopted yet; the other is one whose
# declaration is there and unreadable, where carrying on would move a pin nobody could see.
#
#
# A carriage return is no separator awk knows, so it rides along on the last field. Every pin would
# read as changed, `upgrade` would report a move that moved nothing, and the rewrite would drop the
# return from that one line and leave the file mixed.
#
# **Refused, never handled.** Floor reads this file with `awk` on every path, and a declaration it
# cannot read the same way twice is not one to edit on somebody's behalf.
#
refuse_a_declaration_holding_carriage_returns() {
    [ -r "$DECLARED" ] || return 0
    tr -d '\r' < "$DECLARED" | cmp -s - "$DECLARED" && return 0

    note "$DECLARED holds carriage returns, and floor reads it with awk everywhere"
    note "  give it line feeds, then run this again"
    exit 1
}

refuse_a_declaration_this_cannot_upgrade() {
    [ -r "$DECLARED" ] && return 0
    [ -e "$DECLARED" ] && { note "$DECLARED is there and cannot be read"; exit 3; }

    note "there is no $DECLARED here, so there is no pin to move"
    note "  a repository declares its first reach with: sh adopt.sh adopt <judge> <adapter>"
    exit 1
}

#
# Every `@adapter` reach, as `line fields judge adapter pin`.
#
# **The field count travels with it.** Floor reads everything after the id as the pin, so a sixth
# word is part of one — and a line this cannot read back the way floor will is a line it must not
# rewrite. A reach of any other transport never appears here at all.
#
adapter_reaches() {
    awk '!/^[ \t]*#/ && $1 == "reach" && $3 == "@adapter" { print FNR, NF, $2, $4, $5 }' "$DECLARED"
}

# `judged.sh` states the same rule about itself: a green pass over an empty set certifies nothing,
# and *nothing to move* would read exactly like *everything already moved*.
refuse_a_declaration_naming_no_adapter() {
    [ -n "$1" ] && return 0

    note "$DECLARED names no @adapter reach, so there is no pin here to move"
    note "  a reach through a shipped adapter is written by: sh adopt.sh adopt <judge> <adapter>"
    exit 1
}

# A here-doc, not a pipe. Both tallies and `PENDING` are raised inside this loop, and anything raised
# in a pipe's subshell dies with it — the failure `judged.sh` and floor's own runner each paid for.
grade_each_reach() {
    while read -r line fields who adapter pin; do
        [ -n "$line" ] || continue

        grade_one "$line" "$fields" "$who" "$adapter" "$pin"
    done <<EOF
$1
EOF
}

# One reach: what it is pinned at, what this plugin ships, and which of the two the file will say.
grade_one() {
    [ "$2" -eq 5 ] \
        || { leave "$3" "its reach carries $2 words, and floor reads everything after the id as one pin"; return; }

    ships "$4" || { leave "$3" "this plugin ships no adapter called [$4]"; return; }

    now=$(digest_on_disk "$(adapter_file "$4")")
    is_a_digest "$now" || { leave "$3" "git gave no digest for [$(adapter_file "$4")]"; return; }

    [ "$5" = "$now" ] && { say "  ok     $3 is reached at the content this plugin ships"; return; }

    say "  moved  $3"
    say "         was $5"
    say "         now $now"

    PENDING="$PENDING $1 $now"
    MOVED=$((MOVED + 1))
}

# A reach this cannot move, left exactly as it was and counted. A declaration still not naming what
# this plugin ships is not a repository that upgraded.
leave() {
    say "  left   $1 — $2"
    LEFT=$((LEFT + 1))
}

move_what_moved() {
    [ -n "$PENDING" ] || return 0

    rewrite_the_declaration "$PENDING" || fail_unwritable "$DECLARED"
}

#
# The pin on each line named, replaced where it stands.
#
# Everything before it and everything after it is copied byte for byte, so the commit that moves a
# pin shows one word changing. Rebuilding the line through awk's own separator would collapse the
# spacing somebody chose, and that lands in a diff as a rewrite of a line nobody touched.
#
# `cp` onto the file rather than `mv` over it, which keeps whatever permissions the repository gave
# its own declaration.
#
rewrite_the_declaration() {
    mkdir -p "$WORK" || return 1

    awk -v pending="$1" '
        BEGIN { n = split(pending, said, " "); for (i = 1; i < n; i += 2) now[said[i]] = said[i + 1] }

        FNR in now && match($0, /[^ \t]+[ \t]*$/) {
            print substr($0, 1, RSTART - 1) now[FNR] substr($0, RSTART + length($NF))
            next
        }
        { print }
    ' "$DECLARED" > "$WORK/judged" || return 1

    cp "$WORK/judged" "$DECLARED"
}

# Silence would read as success. Three outcomes, and each says what a person does next.
verdict() {
    [ "$MOVED" -gt 0 ] \
        && say "moved $MOVED pin(s) in $DECLARED. Nothing is staged and nothing is committed."

    [ "$LEFT" -gt 0 ] && {
        say "$LEFT reach(es) were left exactly as they were, and are still not what this plugin ships."
        return 1
    }

    [ "$MOVED" -gt 0 ] && return 0

    say "every pin already names the content this plugin ships. Nothing was written."
}

# --- what a digest is, and where an adapter is ---

# The one place a shipped adapter is ever looked for, and the same path `run.sh` builds.
adapter_file() { printf '%s/adapters/%s/run.sh' "$PLUGIN_ROOT" "$1"; }

# What the file on disk actually is, as git names content. `--no-filters` so a pin taken on one
# platform means the same file on the next.
digest_on_disk() { git hash-object --no-filters -- "$1" 2>/dev/null; }

# A git blob digest, and nothing that merely reads like one. Forty hex for the object format git
# uses by default, sixty-four for a repository built on sha256.
is_a_digest() {
    case $1 in
        *[!0-9a-f]*) return 1 ;;
    esac
    [ "${#1}" -eq 40 ] || [ "${#1}" -eq 64 ]
}

# Read from the directory, never from a list. Floor core names no vendor, so the only place the set
# lives is what the plugin ships.
adapters_this_plugin_ships() {
    for at in "$PLUGIN_ROOT"/adapters/*/run.sh; do
        [ -f "$at" ] || continue

        at=${at%/run.sh}
        printf '%s\n' "${at##*/}"
    done
}

adapters_on_one_line() {
    said=
    for one in $(adapters_this_plugin_ships); do
        said="${said:+$said, }$one"
    done

    printf '%s' "${said:-none}"
}

# --- one voice ---

say() { printf '%s\n' "$1"; }

note() { printf 'floor: %s\n' "$1" >&2; }

fail_unwritable() {
    note "could not write $1"
    exit 3
}

main "$@"
