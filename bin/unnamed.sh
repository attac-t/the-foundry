#!/bin/sh
#
# A refusal the page does not name, and a row the code no longer makes.
#
# **`.foundry/refusals.md` says which of floor's refusals may never soften.** A list nothing checks
# drifts from the code the day after it is written, and this is the check.
#
# **One decision is one head, one code and one message.** Two hundred and nine exit sites collapse
# to a hundred and eighty-two decisions — sixteen callers of `active_run` are one decision made
# sixteen times, not sixteen. `bin/refusals.sh` reads the sites and this compares them.
#
# **A row with no word is refused.** A blank is the judgement nobody has made, and a page that
# reports it as absent is worth more than one that guesses `default`.
#
# Usage: sh bin/unnamed.sh
#
# Exit: 0 the page and the code agree, 1 they do not, 3 neither could be read.

set -eu

cd "$(dirname "$0")/.."

#
# **Both are settable, because a check nobody can point at a fixture cannot be driven.** Its own
# suite writes a page and a script and runs this against them, and neither exists in the tree.
readonly PAGE=${FOUNDRY_REFUSALS_PAGE:-.foundry/refusals.md}
readonly READS=${FOUNDRY_REFUSALS_READS:-plugins/floor/bin/run.sh}

note() { printf '%s\n' "$*" >&2; }

main() {
    #
    # **Gate 25 ran on every branch and its own suite ran on none.** Seventeen cases sat green and
    # unguarded until 20 September, when a sweep of `tests/` found four suites nothing executed.
    #
    # Five gates already do this in one line. This is the sixth, and it adds no gate — the same
    # check answers, and now it answers for its own cases first.
    #
    # **It falls through, and `durable` does not.** That one runs its suite and exits, so a gate
    # calling it with `audit` runs the cases and never the live comparison. Here the live comparison
    # is the whole point of gate 25, so a green suite carries on into it. `bytes` is the shape
    # copied.
    [ "${1:-check}" = audit ] && { bash tests/unnamed.sh || exit 1; }

    [ -r "$PAGE" ]  || fail 3 "[$PAGE] could not be read"
    [ -r "$READS" ] || fail 3 "[$READS] could not be read"

    decisions_in_code > "$CODE"
    decisions_on_page > "$SAID"

    [ -s "$CODE" ] || fail 3 'the reader found no refusal, so nothing here was compared'

    say_what_is_missing
    say_what_is_stale
    say_what_has_no_word

    [ "$wrong" -eq 0 ] && { printf 'unnamed — %s decisions, and the page names every one.\n' "$(grep -c . "$CODE")"; return 0; }
    return 1
}

# The code's own answer, deduplicated. `refusals.sh` prints one line per site and this page holds
# one row per decision, so the sort is the whole of the difference between them.
decisions_in_code() { sh "$(dirname "$0")/refusals.sh" "$READS" | sort -u; }

#
# The page's rows, in the reader's shape.
#
# **A numeric code is what makes a row a decision.** The word table at the top holds `invariant`,
# `answer` and `default` in backticks, so a test on the fenced head alone read three definitions as
# three refusals the code no longer makes.
decisions_on_page() {
    awk -F'|' '$2 ~ /^ `[a-z_]+` $/ && $3 ~ /^ *[0-9]+ *$/ {
        head = $2; gsub(/[ `]/, "", head)
        code = $3; gsub(/ /, "", code)
        said = $5; sub(/^ /, "", said); sub(/ $/, "", said)
        if (said == "\xe2\x80\x94") said = ""
        printf "%s\t%s\t%s\n", head, code, said
    }' "$PAGE" | sort -u
}

say_what_is_missing() {
    gone=$(comm -23 "$CODE" "$SAID")
    [ -z "$gone" ] && return 0

    note 'unnamed — the code refuses these and the page does not say so:'
    printf '%s\n' "$gone" | sed 's/^/  /' >&2
    wrong=$((wrong + 1))
}

# A row the code stopped making. Kept apart from a missing one, because the remedies are opposite:
# one wants a judgement written, the other wants a line deleted.
say_what_is_stale() {
    left=$(comm -13 "$CODE" "$SAID")
    [ -z "$left" ] && return 0

    note 'unnamed — the page names these and the code no longer refuses them:'
    printf '%s\n' "$left" | sed 's/^/  /' >&2
    wrong=$((wrong + 1))
}

# A row nobody has judged. It is not a `default` until somebody says so.
say_what_has_no_word() {
    blank=$(awk -F'|' '$2 ~ /^ `[a-z_]+` $/ && $3 ~ /^ *[0-9]+ *$/ { w = $4; gsub(/ /, "", w); if (w == "") print $2 "|" $3 }' "$PAGE")
    [ -z "$blank" ] && return 0

    note "unnamed — $(printf '%s\n' "$blank" | grep -c .) rows carry no word, so nobody has judged them"
    wrong=$((wrong + 1))
}

fail() { note "unnamed: $2"; exit "$1"; }

wrong=0
CODE=$(mktemp) || exit 3
SAID=$(mktemp) || exit 3
trap 'rm -f "$CODE" "$SAID"' EXIT INT TERM
main "$@"
