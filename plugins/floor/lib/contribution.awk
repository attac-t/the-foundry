# The grammar of a contribution: what one member's shaping entry point printed, a line at a time.
#
# Seven words open a line. `propose <Kind> <text>` is a clause, and `<Kind>` is `Gate`, `Judged` or
# `Decided`, exactly. `why`, `evidence`, `objection`, `unknown` and `recommend` each carry text, and
# `nothing` stands alone: the member has nothing to propose.
#
# A field line names the proposal nearest above it. So a `why`, `evidence` or `recommend` line above
# every proposal is about nothing, while an `objection` or `unknown` there names none.
#
# `nothing` may stand beside objections and unknowns that name no proposal, and never beside a
# `propose` line, whichever of the two comes first.
#
# **A line is read as A1 reads a yes, less its backticks**: spaces and a carriage return go at either
# end, and the first word is read in any case. A yes also loses one pair of backticks, since a person
# may copy it from a rendered question. A member prints its lines, and each must open with one of the
# seven words, so a line wrapped in backticks is out of shape, and it is refused, never unwrapped.
#
# A blank line is no line. A proposal's text holds no tab or carriage return, as `is_one_line` reads a
# clause, so what this takes `introduce` takes too.
#
# Prints `<proposal>\t<word>\t<text>` for each line: the proposal it names, 0 for none, the word
# folded, and the rest of the line. The first line out of shape prints alone, as `<number>\t<line>`,
# and exits 1. With no line of words it prints nothing, and exits 4.
#
# **Nothing is repaired.** One line out of shape refuses the whole contribution.

BEGIN { name_the_seven_words() }

!refused { read_a_line() }

END { finish() }

function name_the_seven_words(   n, i, word) {
    n = split("propose why evidence objection unknown recommend nothing", word, " ")
    for (i = 1; i <= n; i++) seven[word[i]] = 1
}

function read_a_line(   line, space, word, rest) {
    if ($0 ~ /^[ \t\r]*$/) return

    line = trimmed($0)
    space = index(line, " ")
    word = tolower(space ? substr(line, 1, space - 1) : line)
    rest = space ? substr(line, space + 1) : ""

    if (!in_shape(word, rest)) { refuse(); return }
    kept[++taken] = (named + 0) "\t" word "\t" rest
}

function in_shape(word, rest) {
    if (!(word in seven)) return 0
    if (word == "nothing") return nothing_alone(rest)
    if (rest == "") return 0

    if (word == "propose") return a_proposal(rest)
    if (word == "objection" || word == "unknown") return 1
    return named > 0
}

# A clause: its kind exactly, one space, then text holding no tab or carriage return. A text opening
# with a space would read two ways, since `read` drops that space and `substr` keeps it.
function a_proposal(rest) {
    if (said_nothing) return 0
    if (rest !~ /^(Gate|Judged|Decided) [^ ]/) return 0
    if (rest ~ /[\t\r]/) return 0

    named++
    return 1
}

function nothing_alone(rest) {
    if (rest != "" || named > 0) return 0

    said_nothing = 1
    return 1
}

function trimmed(said) {
    sub(/^[ \r]+/, "", said)
    sub(/[ \r]+$/, "", said)
    return said
}

function refuse() {
    printf "%d\t%s\n", NR, $0
    refused = 1
}

function finish(   i) {
    if (refused) exit 1
    if (!taken) exit 4

    for (i = 1; i <= taken; i++) print kept[i]
}
