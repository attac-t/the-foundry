#!/bin/sh
#
# The review chain, made mechanical. See README.md.
#
# Panel already promised this: the adversary produces a verdict and
# structurally cannot write it, and yet `/verdict` records that.
# None of it is enforced, so an invoked verdict went nowhere.
#
# This does not change what Panel is. It refuses the one shortcut that made the promise advisory.
#
# Two numbers live here, and they are not the same number:
#
#   the slot   the filename's leading number. A sequence over the directory, so two records never
#              collide. `next` answers it and `record` uses it. Nothing reads it back.
#   the round  where a verdict sits in one review's chain. It lives in the `Judged:` stamp, written
#              by `record`. `round` answers it and `prior` matches on it.
#
# They coincide while a directory holds one review, and only there. That coincidence shipped a chain
# nobody could validate: `prior` read the slot as the round, so a review whose round one landed in
# slot 017 had no round one at all, and every round of every real chain here refused.
#
# **A chain is a directory and a review, not a directory.** A review with no stamp in a directory is
# on round one — that is what two reviews in one directory means, and it is the only way to be round
# one. Whoever convenes a panel owns the choice of review name; nothing here can check it.
#
# `set -e` is off: `prior` for round 1 exits 0 with no output, which is an answer.
#
# Exit codes:
#   0  answered
#   1  a prior round was claimed and no verdict stamps it — fail closed
#   2  asked for something this does not do

set -u

main() {
    action=${1:-}
    [ "$#" -gt 0 ] && shift

    case "$action" in
        next)   next_slot   "${1:-}" ;;
        round)  next_round  "${1:-}" "${2:-}" ;;
        prior)  prior_round "${1:-}" "${2:-}" "${3:-}" ;;
        record) record_verdict "${1:-}" "${2:-}" "${3:-}" ;;
        *)     usage; exit 2 ;;
    esac
}

usage() {
    cat <<'EOF'
panel verdicts — the review chain.

  verdicts.sh next   <dir>                     the slot the next record takes
  verdicts.sh round  <dir> <review>            the round that review writes next
  verdicts.sh prior  <dir> <round> <review>    the verdict round-1 must read, or exit 1
  verdicts.sh record <dir> <role> <review>     write what a judge returned, on stdin
EOF
}

note() { printf 'panel: %s\n' "$1" >&2; }

#
# **A path that is not there is a mistake, never a new chain.** The comment here used to say those
# two look the same, and they did: one mistyped directory answered `001`, and a review on its fifth
# round was handed to a judge as its first.
#
# A real directory holding no rounds is still a new chain. That is the only way to be round one.
ensure_the_chain_exists() {
    [ -n "$1" ] || { note "$2 needs a verdicts directory"; exit 2; }
    [ -d "$1" ] || { note "no directory at [$1] — a chain nobody made is not a chain with no rounds"; exit 2; }
}

# --- the slot ---

# The filename's leading number. Never a round, and read back nowhere but here.
slot_of() { name=${1##*/}; printf '%s\n' "${name%%-*}"; }

# Every slot taken in this directory. The `case` drops a name that is not numbered, and drops the
# unmatched glob with it — that is the pattern itself, which starts with a star.
slots() {
    for file in "$1"/*-verdict.md; do
        case ${file##*/} in [0-9]*) slot_of "$file" ;; esac
    done
}

# The highest slot taken, or nothing. Nothing is what a directory holding no record looks like.
last_slot() { slots "$1" | sort -n | tail -1 | sed 's/^0*//'; }

# The slot the next record takes, padded so a sorted listing reads in order.
next_slot() {
    ensure_the_chain_exists "$1" next

    last=$(last_slot "$1")
    [ -n "$last" ] || { note "no records at [$1] — this is a new chain"; last=0; }

    printf '%03d\n' "$(( last + 1 ))"
}

# --- the round ---

#
# The round this review writes next: one more than the highest it has stamped here.
#
# Slots run on across every review in the directory; rounds do not. A review sharing a directory with
# four others still opens on round one, and its round two reads its own round one.
next_round() {
    ensure_the_chain_exists "$1" round
    [ -n "$2" ] || { note "round needs the review it is counting"; exit 2; }
    refuse_unless_a_review "$2"

    last=$(rounds_of "$1" "$2" | sort -n | tail -1)
    [ -n "$last" ] || { note "no round for [$2] at [$1] — this review starts here"; last=0; }

    printf '%d\n' "$(( last + 1 ))"
}

# Every round this review has stamped in this directory.
rounds_of() {
    for file in "$1"/*-verdict.md; do
        [ -f "$file" ] || continue

        stamp=$(the_stamp "$file")
        [ "${stamp#* }" = "$2" ] && printf '%s\n' "${stamp%% *}"
    done
}

#
# What this file's stamp says, as `<round> <review>`, or nothing.
#
# `record` writes the title, a blank line, then `Judged: <review> R<round>` — so the stamp is line
# three and every line after it is the judge's. A search of the whole file let a body carrying its
# own `Judged: R1` claim a chain it was never part of.
#
# **The round comes first here and the review second**, which is why a caller can split the two with
# `${stamp%% *}` and `${stamp#* }` and still hand back a review with spaces in it.
#
# A comma opens a note the recorder never writes, and six of the sixteen records here carry one. It
# is cut, and `refuse_unless_a_review` keeps a comma out of a name so nothing else is cut with it.
the_stamp() {
    awk '
        NR > 3 { exit }
        NR == 3 && $1 == "Judged:" {
            sub(/^Judged:[ \t]*/, "")
            sub(/[ \t]*,.*$/, "")
            if ($NF !~ /^R[0-9]+$/) exit

            round = substr($NF, 2) + 0
            sub(/[ \t]*R[0-9]+[ \t]*$/, "")
            print round, $0
        }
    ' "$1" 2>/dev/null
}

# --- the prior ---

# A positive whole number, leading zeros and all.
is_a_round() {
    case "$1" in ''|*[!0-9]*) return 1 ;; esac

    [ -n "$(printf '%s' "$1" | sed 's/^0*//')" ]
}

# Anything else reached round one's exemption, so a malformed round skipped by malforming.
# One word made `set -u` exit 1, a code already spoken for.
refuse_unless_a_round() {
    is_a_round "$1" && return 0

    note "a round is a positive whole number, not [$1]"
    exit 2
}

#
# The verdict round N must have read, or a refusal.
#
# Round 1 has no prior and exits 0. Later rounds must find a record stamping
# that same review at the round before. Without one the chain restarts in
# silence, the shape which let three rounds judge a retelling instead.
#
prior_round() {
    dir=$1; round=$2; review=$3

    [ -n "$dir" ] && [ -n "$round" ] && [ -n "$review" ] \
        || { note "prior needs a directory, a round and a review"; exit 2; }

    refuse_unless_a_review "$review"
    refuse_unless_a_round "$round"

    want=$(( $(printf '%s' "$round" | sed 's/^0*//') - 1 ))
    [ "$want" -ge 1 ] || return 0

    file=$(verdict_at_round "$dir" "$review" "$want")
    [ -n "$file" ] || {
        note "round $round of [$review] claims a round $want that no verdict stamps — refusing to judge a summary"
        exit 1
    }

    printf '%s\n' "$file"
}

#
# The record stamping this review at this round, or nothing.
#
# **The slot is not read.** This repository's own round one sits in slot 017, and reading the slot as
# the round refused every round of every chain in it. Two reviews in one directory, or a verdict left
# behind by an older charter, are the same case: neither is stamped for this review.
#
# One refusal replaces two. *No record stamps this review at that round* covers both a round nobody
# wrote and a round another review wrote, and telling those apart means reading a stamp the caller
# never asked about.
verdict_at_round() {
    for file in "$1"/*-verdict.md; do
        [ -f "$file" ] || continue

        stamp=$(the_stamp "$file")
        [ "${stamp#* }" = "$2" ] || continue
        [ "${stamp%% *}" = "$3" ] || continue

        printf '%s\n' "$file"
        return 0
    done

    return 1
}

# --- the record ---

#
# Write what a judge returned, at that review's next round, in the next free slot.
#
# The slot, the name, the review and the round are decided here, not by whoever holds the verdict.
# `prior` refuses any record that does not stamp both the review and the round it claims, and a
# model asked to write either might simply forget.
#
# The body is never interpreted. A recorder that edits a verdict is a second author.
#
record_verdict() {
    dir=$1; role=$2; review=$3

    [ -n "$dir" ] && [ -n "$role" ] && [ -n "$review" ] \
        || { note "record needs a directory, a role and a review"; exit 2; }

    case "$role" in
        *[!A-Za-z0-9-]*) note "a role is a plain name, not [$role]"; exit 2 ;;
    esac
    refuse_unless_a_review "$review"

    # An `exit` inside `$( )` ends the subshell, never this. Without these, a refusal either of them
    # made would come back as an empty number and get written — `Judged: <review> R`, unfindable.
    # The guard above keeps both quiet today, which is exactly how a trap like this waits.
    mkdir -p "$dir" || { note "could not write $dir"; exit 2; }
    slot=$(next_slot "$dir")             || exit 2
    round=$(next_round "$dir" "$review") || exit 2
    file="$dir/$slot-$role-verdict.md"

    # Everything is staged before the record exists. A refusal leaves the chain as it was.
    {
        printf '# Verdict %s — %s\n\n' "$slot" "$role"
        printf 'Judged: %s R%s\n\n' "$review" "$round"
        cat
    } > "$file.part" || { rm -f "$file.part"; note "could not write $file"; exit 2; }

    mv "$file.part" "$file" || { rm -f "$file.part"; note "could not write $file"; exit 2; }
    printf '%s\n' "$file"
}

#
# A review is a name, wherever it is named. Every command that takes one asks here, because a name is
# read far more often than it is written and the guard sat on `record` alone.
#
# Ten of the sixteen records here append a round by hand, because `record` did not write one. What
# that costs turns on something a single call cannot see. Passing `<review> R2` every round is
# harmless: the name is stable, `record` adds its own round after it, and the chain reads back.
# **Incrementing it is the reset.** `<review> R1`, then `<review> R2`, and each is a review nobody
# has judged before — three chains of one link, every round its own round one.
#
# One invocation cannot tell those two apart, so both are refused. The stable caller pays a rename
# and is told which word to drop; the other is stopped before it loses a chain.
#
# **The two characters refused belong to the stamp, not to the name.** A comma opens the recorder's
# note, so a name holding one comes back cut short; the stamp is one line, so a name holding a break
# puts its own round in the judge's body. A whitelist would be the wider net and the wrong one — a
# review name is whatever a human called a review, and enumerating an open set is how a gate starts
# refusing honest work.
refuse_unless_a_review() {
    newline='
'
    case "$1" in
        *,*)          note "a review name holds no comma — a comma opens the recorder's note"; exit 2 ;;
        *"$newline"*) note "a review name holds no line break — the stamp is one line"; exit 2 ;;
    esac

    word=${1##* }
    [ "$word" = "$1" ] && return 0
    [ "$word" = "${word#R}" ] && return 0
    is_a_round "${word#R}" || return 0

    note "the round is written here, not passed in — drop the [$word] from [$1]"
    exit 2
}

main "$@"
