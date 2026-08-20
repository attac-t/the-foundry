#!/bin/sh
#
# The review chain, made mechanical. See README.md.
#
# Panel already promised this: the adversary produces a verdict and structurally cannot write it,
# `/verdict` records it, and `craft-verdict` says prior verdicts are input rather than archive. All
# true, and none of it enforced — invoking the judge directly produced a verdict that went nowhere,
# and the next round read the coordinator's retelling instead.
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

# The round after the last one recorded.
#
# **It says which, and still answers.** Refusing is wrong: a coordinator asks this before the
# directory exists, so nothing there is what a new review looks like. A mistyped path looks the same,
# and `001` is the one round `prior_round` exempts.
next_round() {
    [ -n "$1" ] || { note "next needs a verdicts directory"; exit 2; }

    last=$(last_round "$1")
    [ -n "$last" ] || { note "no rounds at [$1] — this is a new chain"; last=0; }

    printf '%03d\n' "$(( last + 1 ))"
}

# The highest round recorded, or nothing. Nothing is what a chain with no rounds looks like.
last_round() { rounds "$1" | sort -n | tail -1 | sed 's/^0*//'; }

#
# The verdict round N must have read, or a refusal.
#
# Round 1 has no prior, so it answers nothing and exits 0. Every later round must find a record that
# names the same review — otherwise the chain is being started fresh while claiming to continue one,
# which is exactly the shape that let three rounds judge a summary.
#
prior_round() {
    dir=$1; round=$2; review=$3

    [ -n "$dir" ] && [ -n "$round" ] && [ -n "$review" ] \
        || { note "prior needs a directory, a round and a review"; exit 2; }

    want=$(( $(printf '%s' "$round" | sed 's/^0*//;s/^$/0/') - 1 ))
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
# The number, the name and the stamp are decided here rather than by whoever is holding the verdict.
# `prior` refuses a record that does not name its review — which is only worth anything if something
# guarantees a recorded verdict carries one. A model asked to write the file might not, and the
# refusal would then fire on an honest round.
#
# The body arrives on stdin and is never interpreted. A recorder that edits a verdict is a second
# author.
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
