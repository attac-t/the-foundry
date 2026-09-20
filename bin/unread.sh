#!/bin/sh
#
# Open issues whose `## Done when` list nobody has ever ticked, and that merged work names.
#
# Measured when this was built, 20 September: 178 of 210 open issues carried a list with not one
# tick. Two read by hand that day were substantially built — one nine boxes of nine, with twelve
# driven cases, and one four of ten. Neither said so, so both read as work nobody had started.
#
# **The current figures are the report's own first line**, and this one is history. A number in a
# header goes stale the day after it is written, which is the fault the whole page is about.
#
# `.claude/rules/closing.md` names the shape: their boxes were not failing, they were unread.
#
# **It lists. It never judges a box.** A box saying *a rejection blocks delivery* cannot be graded
# from the tree without deciding what blocks means and which file holds it. A report that tries
# returns maybes nobody reads, or is confidently wrong — and a wrong *this looks met* is how a box
# gets ticked without being checked. The owner delegate refused that shape on 20 September and
# approved this one.
#
# So one claim only: **work landed that names this issue, and nobody went back to the list.**
#
# Usage: sh bin/unread.sh [<target>]     default target: main, or FOUNDRY_UNREAD_TARGET
#
# Exit: 0 nothing to read, 1 at least one issue owes a reading, 3 the forge could not be asked.
#
# Not a gate. It reaches the network, and `.claude/rules/plugins.md` refuses a gate that goes red on
# a train. `CONTRIBUTING.md` lists it beside the other checks a person runs.

set -eu

readonly TARGET="${1:-${FOUNDRY_UNREAD_TARGET:-main}}"

# How many merges make an issue worth reading first. The delegate's failure signal was a list that
# passes twenty and nobody opens, so the ranking is the thing that keeps it readable.
readonly FLOOR="${FOUNDRY_UNREAD_FLOOR:-1}"

readonly TAB="$(printf "	")"
readonly named="${TMPDIR:-/tmp}/unread-named.$$"
readonly blank="${TMPDIR:-/tmp}/unread-blank.$$"

note() { printf '%s\n' "$*" >&2; }
say()  { printf '%s\n' "$*"; }

main() {
    trap 'rm -f "$named" "$blank"' EXIT

    refuse_without_a_forge
    refuse_without_the_target

    history_names_issues > "$named"
    issues_with_a_list   > "$blank" || exit 3

    report
}

#
# The git half works anywhere. The issue half does not, and saying which is which is the whole of
# what a reader needs when this refuses.
refuse_without_a_forge() {
    command -v gh >/dev/null 2>&1 && return 0

    note 'unread — the history half is git and runs anywhere. The list half needs a forge adapter'
    note 'unread — no `gh` on this host, so the open lists cannot be read. Nothing was judged'
    exit 3
}

refuse_without_the_target() {
    git rev-parse --verify --quiet "$TARGET" >/dev/null 2>&1 && return 0

    note "unread — [$TARGET] is not a ref here. Name the branch merged work lands on"
    exit 3
}

#
# Every issue number the merged history names, as `count<TAB>number<TAB>sha sha sha`.
#
# **Every commit reachable from the target, never `--first-parent`.** A merge commit carries the
# request number and nothing else; `Refs #N` is written on the branch commits the merge folds in.
# First-parent drops exactly the lines this reads — it measured zero and read like an answer.
#
# **One record per commit, and a body spans lines.** So each commit is folded onto a line of its own
# behind `\001`, which no commit message holds. Reading the log line by line would credit a subject
# to the body above it.
history_names_issues() {
    git log "$TARGET" --format='%x01%h %s %b' |
        tr '\n' ' ' | tr '\001' '\n' |
        awk '{
            sha = $1
            while (match($0, /#[0-9]+/)) {
                print substr($0, RSTART + 1, RLENGTH - 1), sha
                $0 = substr($0, RSTART + RLENGTH)
            }
        }' |
        sort -k1,1n -k2,2 -u |
        awk -v t="$TAB" '{ shas[$1] = shas[$1] " " $2; seen[$1]++ }
            END { for (n in seen) print seen[n] t n t substr(shas[n], 2) }'
}

#
# Every open issue carrying a list, as `ticked<TAB>number<TAB>title`, where ticked is 1 or 0.
#
# **REST, and that is not a preference.** GraphQL is the bucket a room full of workers empties
# first, and on 18 September every call through it was refused for hours while REST sat untouched.
# `select(has("pull_request") | not)` because REST counts a request as an issue and `gh issue` does
# not.
#
# **Both halves, because one count hid a pass.** On 20 September ten issues were read and nine
# gained a first tick. The untouched count fell by one, because eight issues were filed the same
# day. A reader of that number alone would have said nothing happened.
#
# So this carries the tick state too, and `report` says how many lists have been touched at all. A
# single figure cannot say which half moved — that is the page's own lesson, met by its own
# measure.
issues_with_a_list() {
    gh api "repos/{owner}/{repo}/issues?state=open&per_page=100" --paginate \
       --jq '.[]
             | select(has("pull_request") | not)
             | (.body // "") as $b
             | select($b | test("(^|\n)\\s*- \\[[ xX]\\] "))
             | (if   ($b | test("(^|\n)\\s*- \\[[xX]\\] ")) then "1"
                elif ($b | test("\\*\\*(unmeetable|wrong when written|ungateable|unreached)")) then "2"
                else "0" end) as $t
             | "\($t)\t\(.number)\t\(.title)"' 2>/dev/null
}

#
# A row per issue, most-named first, so the top of the list is where to look.
report() {
    rows=$(joined | sort -rn) || rows=

    say_how_the_lists_stand

    [ -n "$rows" ] || {
        say 'unread — every open list with work behind it has been read'
        exit 0
    }

    say "unread — these carry a list nobody ticked, and [$TARGET] names them:"
    printf '%s\n' "$rows" | while IFS="$TAB" read -r count number title shas; do
        printf '  %3s  #%-5s %s\n' "$count" "$number" "$title"
        printf '       %s\n' "$(first_few "$shas")"
    done

    say ''
    say 'unread — none of that says a box is met. It says work landed and the list was never read.'
    exit 1
}

#
# **Three numbers, because two of them hid something.** Read the untouched count alone on a day when
# issues were also filed, and a real reading looks like nothing.
#
# **And a reading can end with nothing to tick.** Three issues were read here on 20 September and
# every box came back unreachable. Ticking one would be a lie and leaving them made a queue that
# never shortens, so a box naming a state counts as read — the four words `closing.md` gives and
# `bin/unticked.sh` already reads.
say_how_the_lists_stand() {
    untouched=$(awk -F"$TAB" '$1 == "0"' "$blank" | grep -c .) || untouched=0
    touched=$(awk -F"$TAB" '$1 == "1"' "$blank" | grep -c .)   || touched=0
    stated=$(awk -F"$TAB" '$1 == "2"' "$blank" | grep -c .)    || stated=0

    say "unread — $(( untouched + touched + stated )) open lists: $touched carry a tick, $stated say why a box cannot be met, $untouched carry none."
    say ''
}

# Three is enough to argue with. The count above says how many more there are.
first_few() {
    set -- $1
    [ "$#" -le 3 ] && { printf '%s' "$*"; return 0; }
    printf '%s %s %s and %d more' "$1" "$2" "$3" "$(( $# - 3 ))"
}

# One pass over each file, because an issue nothing names is not on this report at all.
joined() {
    while IFS="$TAB" read -r ticked number title; do
        [ "$ticked" = 0 ] || continue

        found=$(named_row "$number")
        [ -n "$found" ] || continue

        count=${found%%"$TAB"*}
        [ "$count" -ge "$FLOOR" ] || continue

        printf '%s%s%s%s%s%s%s\n' \
               "$count" "$TAB" "$number" "$TAB" "$title" "$TAB" "${found#*"$TAB"}"
    done < "$blank"
}

named_row() {
    awk -v t="$TAB" -v want="$1" -F"$TAB" '$2 == want { print $1 t $3; exit }' "$named"
}

main "$@"
