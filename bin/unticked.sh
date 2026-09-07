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

# A body carrying an unticked box.
#
# `- [ ]` and nothing looser. A plain `- ` bullet is the older shape and cannot be ticked at all —
# `closing.md` calls that unrecordable, counts 219 of them, and says converting one is worth it only
# when somebody is about to rely on it. Not this script's question.
holds_an_unticked_box() { printf '%s' "$1" | grep -q -- '- \[ \]'; }

count_of() { printf '%s' "$1" | grep -c -- '- \[ \]' || true; }

main() {
    numbers=$(closed_numbers) || { note 'unticked — GitHub could not be asked'; exit 3; }
    [ -n "$numbers" ] || { note 'unticked — no closed issues came back'; exit 3; }

    : > "$found"
    for number in $numbers; do
        body=$(body_of "$number")
        holds_an_unticked_box "$body" || continue

        printf '  #%-5s %s unticked
' "$number" "$(count_of "$body")"
        printf 'x
' >> "$found"
    done

    left=$(grep -c . "$found" || true)
    rm -f "$found"

    [ "$left" = 0 ] && { printf 'unticked — none in the last %s closed
' "$LIMIT"; exit 0; }

    printf 'unticked — %s of the last %s closed issues have a box nobody ticked
' "$left" "$LIMIT"
    exit 1
}

main "$@"
