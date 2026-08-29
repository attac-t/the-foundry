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
# `set -e` is off: `prior` for round 1 exits 0 with no output, which is an answer.
#
# Exit codes:
#   0  answered
#   1  a prior round was claimed and no verdict records it — fail closed
#   2  asked for something this does not do

set -u

main() {
    action=${1:-}
    [ "$#" -gt 0 ] && shift

    case "$action" in
        next)   next_round  "${1:-}" ;;
        prior)  prior_round "${1:-}" "${2:-}" "${3:-}" ;;
        record) record_verdict "${1:-}" "${2:-}" "${3:-}" ;;
        *)     usage; exit 2 ;;
    esac
}

usage() {
    cat <<'EOF'
panel verdicts — the review chain.

  verdicts.sh next   <dir>                     the round number to write next
  verdicts.sh prior  <dir> <round> <review>    the verdict round-1 must read, or exit 1
  verdicts.sh record <dir> <role> <review>     write what a judge returned, on stdin
EOF
}

note() { printf 'panel: %s\n' "$1" >&2; }

# Verdict files are `NNN-<role>-verdict.md`. The number is the round.
rounds() { ls "$1" 2>/dev/null | sed -n 's/^\([0-9][0-9]*\)-.*-verdict\.md$/\1/p'; }

#
# The round after the last one recorded.
#
# **A path that is not there is a mistake, never a new chain.** The comment here used to say those
# two look the same, and they did: one mistyped directory answered `001`, and a review on its fifth
# round was handed to a judge as its first.
#
# A real directory holding no rounds is still a new chain. That is the only way to be round one.
next_round() {
    [ -n "$1" ] || { note "next needs a verdicts directory"; exit 2; }
    [ -d "$1" ] || { note "no directory at [$1] — a chain nobody made is not a chain with no rounds"; exit 2; }

    last=$(last_round "$1")
    [ -n "$last" ] || { note "no rounds at [$1] — this is a new chain"; last=0; }

    printf '%03d\n' "$(( last + 1 ))"
}

# The highest round recorded, or nothing. Nothing is what a chain with no rounds looks like.
last_round() { rounds "$1" | sort -n | tail -1 | sed 's/^0*//'; }

# A round is a positive whole number. Anything else reached round
# one's exemption, so a malformed round skipped by malforming.
# One word made `set -u` exit 1, a code already spoken for.
refuse_unless_a_round() {
    case "$1" in ''|*[!0-9]*) not_a_round "$1" ;; esac

    [ -n "$(printf '%s' "$1" | sed 's/^0*//')" ] || not_a_round "$1"
}

not_a_round() {
    note "a round is a positive whole number, not [$1]"
    exit 2
}

#
# The verdict round N must have read, or a refusal.
#
# Round 1 has no prior and exits 0. Later rounds must find a record
# naming that review. Without one the chain restarts in silence,
# the shape which let three rounds judge a retelling instead.
#
prior_round() {
    dir=$1; round=$2; review=$3

    [ -n "$dir" ] && [ -n "$round" ] && [ -n "$review" ] \
        || { note "prior needs a directory, a round and a review"; exit 2; }

    refuse_unless_a_round "$round"

    want=$(( $(printf '%s' "$round" | sed 's/^0*//') - 1 ))
    [ "$want" -ge 1 ] || return 0

    file=$(find_verdict "$dir" "$want")
    [ -n "$file" ] || {
        note "round $round claims a round $want that no verdict records — refusing to judge a summary"
        exit 1
    }

    # A record from another review is not this chain's history. Two reviews in one directory, or a
    # verdict left behind by an older charter, would otherwise satisfy a round it never saw.
    grep -Fq -- "$review" "$file" || {
        note "the round $want verdict does not name [$review] — that is another review's chain"
        exit 1
    }

    printf '%s\n' "$file"
}

#
# Write what a judge returned, at the next round, stamped with the review it judged.
#
# The number, name and stamp are decided here, not by whoever holds
# the verdict. `prior` refuses any record that does not name its
# review, and a model asked to write one might simply forget.
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

    mkdir -p "$dir" || { note "could not write $dir"; exit 2; }
    round=$(next_round "$dir")
    file="$dir/$round-$role-verdict.md"

    # Everything is staged before the record exists. A refusal leaves the chain as it was.
    {
        printf '# Verdict %s — %s\n\n' "$round" "$role"
        printf 'Judged: %s\n\n' "$review"
        cat
    } > "$file.part" || { rm -f "$file.part"; note "could not write $file"; exit 2; }

    mv "$file.part" "$file" || { rm -f "$file.part"; note "could not write $file"; exit 2; }
    printf '%s\n' "$file"
}

find_verdict() {
    ls "$1" 2>/dev/null \
        | awk -v want="$2" '{ n = $0; sub(/-.*/, "", n); if (n + 0 == want + 0 && /-verdict\.md$/) { print; exit } }' \
        | sed "s|^|$1/|"
}

main "$@"
