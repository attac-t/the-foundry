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
# **A box that says why it is open is not one of them.** `closing.md` names four states a box can
# record instead of a tick, and a box leading with one of them is answered. Measured 19 September:
# thirty-four open boxes across thirteen closed issues, and seventeen already said which.
#
# Usage: sh bin/unticked.sh [limit]
#
# Exit: 0 no box says nothing, 1 at least one does, 3 GitHub could not be asked.
#
# Not a gate. It reaches the network, and `.claude/rules/plugins.md` refuses a gate that goes red on
# a train. `CONTRIBUTING.md` lists it beside the other checks a person runs when they apply.

set -eu

readonly LIMIT="${1:-60}"

# The field separator the index uses. A reason holds no space and a number holds none either, but
# `read` with the default IFS would still fold an empty reason into nothing to read.
readonly TAB="$(printf "	")"
readonly found="${TMPDIR:-/tmp}/unticked.$$"
readonly refused="${TMPDIR:-/tmp}/unticked-declined.$$"

note() { printf '%s\n' "$*" >&2; }

#
# The closed issues, newest first, as `number<TAB>why it closed`.
#
# **REST, and that is not a preference.** `gh issue list` and `gh issue view` both speak GraphQL,
# and GraphQL is the bucket a room full of workers empties first. On 18 September every call here
# was refused for hours while the REST limit sat untouched at five thousand — so the one report that
# says what the tree owes went dark exactly when the most work was landing.
#
# **One call for both facts.** Asking why an issue closed used to be a second request per issue, so
# a sweep of a hundred and sixty-seven cost three hundred and thirty-four.
#
# **`select` and `head` together, because REST counts a pull request as an issue.** `gh issue list`
# does not, so a page of a hundred here is not a hundred issues. Filtering alone made a window of
# sixty read ten and say so honestly — an honest number for a promise nobody kept. The limit means
# issues, so the pages are walked until that many are found.
#
# **The suite drives the window and not the filter.** Its `gh` is a shell stub, so nothing there runs
# `--jq` — a case can prove that sixty of a hundred and sixty-seven were read, and cannot prove that a
# merged request was one of the hundred and seven left out. That half is driven by running it.
closed_index() {
    gh api "repos/{owner}/{repo}/issues?state=closed&per_page=100&sort=created&direction=desc" \
       --paginate \
       --jq '.[] | select(has("pull_request") | not) | "\(.number)\t\(.state_reason // "")"' \
       2>/dev/null | head -n "$LIMIT"
}

# The body of one issue, as it stands. REST, for the reason above.
body_of() { gh api "repos/{owner}/{repo}/issues/$1" --jq '.body // ""' 2>/dev/null; }

#
#
# Why it closed, as the index already read it: `COMPLETED`, `NOT_PLANNED`, or nothing on an older
# close.
#
# **A declined issue's open box is the record, never a lie.** #431 asked for a whole capability
# and closed `NOT_PLANNED`; its ten boxes describe work nobody was going to do. Counting them as
# debt sends the next reader to build something the repository already refused.
#
# Five of thirty-six read that way on 18 September, and four of them were the next four I would
# have picked up.
#
# **Both spellings, because the two readers disagree.** REST answers `not_planned` and GraphQL
# answered `NOT_PLANNED`. Moving to REST and keeping the old word made every declined issue read as
# debt again — five of them, silently, in the one report written to stop exactly that.
declined() {
    case $1 in
        NOT_PLANNED|not_planned) return 0 ;;
    esac
    return 1
}

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
# The four states `closing.md` names for a box that cannot be met yet. A box leading with one of
# them is answered, and counting it as debt sends a reader to read a judgement somebody already
# made.
#
# Measured 19 September across every closed issue: thirteen hold an open box and thirty-four boxes
# between them. **Seventeen name one of these four.** Reporting all thirty-four is twelve parts
# noise, which is the shape this line removes.
readonly STATES='unmeetable|wrong when written|ungateable|unreached'

# Bold, and never the bare word. An issue discusses its own states in prose — #292 argues about
# what ungateable means — and a sentence naming one is not a box claiming one.
stated_of() { unticked_lines "$1" | grep -cE "\*\*($STATES)" || true; }

#
# A box that says something in bold and names none of the four.
#
# **Reported, never counted as debt and never counted as answered.** Three boxes read
# `**unverifiable**` — the check ran and what it read cannot be confirmed afterwards, which is not
# `ungateable`, where no check can exist. The rule names four and the record uses five.
#
# A word here is a question for whoever owns the rule. It is not this script's to settle.
worded_of() {
    unticked_lines "$1" | grep -E '\*\*[A-Za-z]' | grep -vcE "\*\*($STATES)" || true
}

# A box that says nothing at all. This is the debt, and the only thing the exit code follows.
bare_of() { unticked_lines "$1" | grep -vc '\*\*' || true; }

#
#
# How many closed issues there are, so `the last 60` is read against a number.
#
# **A window is honest about its edge, or it is not honest.** At the default this tree reports
# seven and holds forty-four. Both sentences are true and only one of them says which.
#
# **No ceiling now.** `--paginate` walks every page, where the old reader asked for a thousand and a
# repository past that read as a thousand. The pages cost one request each and they are REST.
closed_total() {
    gh api "repos/{owner}/{repo}/issues?state=closed&per_page=100" --paginate \
       --jq '.[] | select(has("pull_request") | not) | .number' 2>/dev/null | grep -c . || true
}

#
# One issue's line: what it owes first, then what it has answered.
#
# **The bare count leads, because it is the only one a reader must act on.** A line reading
# `0 bare` beside seven stated boxes says the issue was closed carefully, and saying nothing about
# it would leave the reader to open it and find that out.
say_one() {
    printf '  #%-5s %s bare' "$1" "$2"
    [ "$3" = 0 ] || printf ', %s stated' "$3"
    [ "$4" = 0 ] || printf ', %s in a word the rule does not name' "$4"
    printf '\n'
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
    index=$(closed_index) || { note 'unticked — GitHub could not be asked'; exit 3; }
    [ -n "$index" ] || { note 'unticked — no closed issues came back'; exit 3; }

    read_count=$(printf %s "$index" | grep -c .)

    : > "$found"
    : > "$refused"

    # A here-doc, and not a pipe. Both tallies are written inside this loop, and a pipeline runs it
    # in a subshell where every count dies with the last line.
    while IFS="$TAB" read -r number reason; do
        [ -n "$number" ] || continue

        body=$(body_of "$number")
        holds_an_unticked_box "$body" || continue

        # A declined issue is counted apart, not counted out. Its boxes are still worth seeing.
        declined "$reason" && { printf 'x\n' >> "$refused"; continue; }

        bare=$(bare_of "$body")
        say_one "$number" "$bare" "$(stated_of "$body")" "$(worded_of "$body")"

        [ "$bare" = 0 ] || printf 'x\n' >> "$found"
    done <<EOF
$index
EOF

    left=$(grep -c . "$found" || true)
    turned_down=$(grep -c . "$refused" || true)
    rm -f "$found" "$refused"

    [ "$left" = 0 ] && { printf 'unticked — no box left open without a reason, in the last %s closed
' "$read_count"; say_what_was_declined "$turned_down"; say_what_was_not_read "$read_count"; exit 0; }

    printf 'unticked — %s of the last %s closed issues hold a box that says nothing
' "$left" "$read_count"
    say_what_was_declined "$turned_down"
    say_what_was_not_read "$read_count"
    exit 1
}

main "$@"
