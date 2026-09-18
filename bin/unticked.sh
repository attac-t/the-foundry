#!/bin/sh
#
# Closed issues whose `## Done when` list still holds an unticked box.
#
# `Closes #N` in a merged pull request flips the state and never touches the body. Nothing else does
# either. On 4 September four issues closed that way held eighteen boxes between them, every one of
# them met and none of them ticked.
#
# `.claude/rules/closing.md` says what that costs: a closed issue with an unticked box is a lie the
# tree tells the next reader, and worse than an open one, because nobody looks again.
#
# **This finds them. It cannot tick them.** A tick is a judgement — did this box hold? — and that
# lives in the pull request and the gate output, not in anything a script can read.
#
# Usage: sh bin/unticked.sh [limit]
#
# Exit: 0 nothing unticked, 1 at least one found, 3 GitHub could not be asked.
#
# Not a gate. It reaches the network, and `.claude/rules/plugins.md` refuses a gate that goes red on
# a train. `CONTRIBUTING.md` lists it beside the other checks a person runs when they apply.

set -eu

readonly LIMIT="${1:-60}"
readonly found="${TMPDIR:-/tmp}/unticked.$$"
readonly refused="${TMPDIR:-/tmp}/unticked-declined.$$"

note() { printf '%s\n' "$*" >&2; }

# The numbers of the closed issues, newest first.
#
# Numbers, not bodies. A body is markdown anyone may write, and folding one to a line through `--jq`
# left a real newline in it here — so a loop reading line by line saw only each body's first line and
# found nothing, every time. **An empty answer was my query, not the tree.**
closed_numbers() {
    gh issue list --state closed --limit "$LIMIT" --json number --jq '.[].number' 2>/dev/null
}

# The body of one issue, as it stands.
body_of() { gh issue view "$1" --json body --jq .body 2>/dev/null; }

#
# Why it closed. `COMPLETED`, `NOT_PLANNED`, or nothing at all on an older close.
#
# **A declined issue's open box is the record, never a lie.** #431 asked for a whole capability
# and closed `NOT_PLANNED`; its ten boxes describe work nobody was going to do. Counting them as
# debt sends the next reader to build something the repository already refused.
#
# Five of thirty-six read that way on 18 September, and four of them were the next four I would
# have picked up.
reason_of() { gh issue view "$1" --json stateReason --jq '.stateReason // ""' 2>/dev/null; }

declined() { [ "$(reason_of "$1")" = NOT_PLANNED ]; }

# A body carrying an unticked box.
#
# `- [ ]` and nothing looser. A plain `- ` bullet is the older shape and cannot be ticked at all —
# `closing.md` calls that unrecordable, counts 219 of them, and says converting one is worth it only
# when somebody is about to rely on it. Not this script's question.
#
# **At the start of a line, because an issue discusses its own boxes.** Unanchored, this counted
# `- [ ]` inside a sentence and inside backticks: #494 read as ten boxes and holds seven, and #746
# read as one and holds none. **A box quoted is not a box open.**
#
# **A struck box is answered, not ignored.** `closing.md` strikes a requirement that was wrong when
# written and leaves the `- [ ]`, so counting it makes a decision look like debt for ever.
unticked_lines() { printf '%s' "$1" | grep -- '^- \[ \]' | grep -v -- '^- \[ \] ~~'; }

holds_an_unticked_box() { [ -n "$(unticked_lines "$1")" ]; }

count_of() { unticked_lines "$1" | grep -c '' || true; }

#
# How many closed issues there are, so `the last 60` is read against a number.
#
# **A window is honest about its edge, or it is not honest.** At the default this tree reports
# seven and holds forty-four. Both sentences are true and only one of them says which.
#
# A thousand is the ceiling, so a repository past that reads as a thousand. Nothing here needs a
# truer number than the one it just failed to reach.
closed_total() {
    gh issue list --state closed --limit 1000 --json number --jq 'length' 2>/dev/null
}

# Issues the repository turned down, said apart from the ones it owes.
say_what_was_declined() {
    [ "$1" = 0 ] && return 0

    printf '           %s more closed as not planned, where an open box is the record
' "$1"
}

# What the window left out, and only when it left something out.
say_what_was_not_read() {
    # `set -e` is on, so the failure has to be taken here. A total nobody could read is a line
    # left unsaid, never a sweep that stops.
    total=$(closed_total) || total=
    case $total in ""|*[!0-9]*) return 0 ;; esac
    [ "$total" -gt "$1" ] || return 0

    printf '           %s more are closed and were not read. Give it a bigger limit
' "$((total - $1))"
}

main() {
    numbers=$(closed_numbers) || { note 'unticked — GitHub could not be asked'; exit 3; }
    [ -n "$numbers" ] || { note 'unticked — no closed issues came back'; exit 3; }

    read_count=$(printf %s "$numbers" | grep -c .)

    : > "$found"
    : > "$refused"
    for number in $numbers; do
        body=$(body_of "$number")
        holds_an_unticked_box "$body" || continue

        # A declined issue is counted apart, not counted out. Its boxes are still worth seeing.
        declined "$number" && { printf 'x
' >> "$refused"; continue; }

        printf '  #%-5s %s unticked
' "$number" "$(count_of "$body")"
        printf 'x
' >> "$found"
    done

    left=$(grep -c . "$found" || true)
    turned_down=$(grep -c . "$refused" || true)
    rm -f "$found" "$refused"

    [ "$left" = 0 ] && { printf 'unticked — none in the last %s closed
' "$read_count"; say_what_was_declined "$turned_down"; say_what_was_not_read "$read_count"; exit 0; }

    printf 'unticked — %s of the last %s closed issues have a box nobody ticked
' "$left" "$read_count"
    say_what_was_declined "$turned_down"
    say_what_was_not_read "$read_count"
    exit 1
}

main "$@"
