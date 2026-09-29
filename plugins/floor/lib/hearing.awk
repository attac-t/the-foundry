# Hears every answer on an item once, against who may answer and whom floor skips.
#
# stdin is the source's `receive`, `<who>\t<when>\t<words>` a line. `ENVIRON["hands"]` holds the hands
# the base names, one a line. `ENVIRON["speakers"]` holds `speaker`'s lines: the account floor writes as
# now, then `<author>\t<question>\t<when>` for each question asked. Every account arrives folded.
#
# `ENVIRON["strikable"]` holds the questions a no may strike, one a line: the authorisation questions
# of the clauses a panel proposed. A no to any other question is no yes, as it always was.
#
# Prints `heard\t<question>\t<who>\t<when>\t<words>` for each yes it hears, `struck` in the same fields
# for each no, and `unread\t<who>\t<when>\t<why>` for each named hand's comment that authorises nothing.
# A line it drops is said on stderr, and one bad line never stops the rest.

BEGIN {
    FS = "\t"
    name_the_hands(ENVIRON["hands"])
    name_the_speakers(ENVIRON["speakers"])
    name_the_strikable(ENVIRON["strikable"])
}

$0 == "" { next }

{ hear() }

END { close_the_comment() }

function name_the_hands(said,   n, i, line) {
    n = split(said, line, "\n")
    for (i = 1; i <= n; i++) if (line[i] != "") hand[line[i]] = 1
}

function name_the_strikable(said,   n, i, line) {
    n = split(said, line, "\n")
    for (i = 1; i <= n; i++) if (line[i] != "") strikable[line[i]] = 1
}

#
# The first line is the account floor writes as now. Each after it is a question, who first asked it,
# and when. **Both kinds of account are skipped**, so a yes written under a login floor has since left
# still reads as floor's own.
#
function name_the_speakers(said,   n, i, line, field) {
    n = split(said, line, "\n")
    skipped[line[1]] = 1

    for (i = 2; i <= n; i++) {
        if (split(line[i], field, "\t") < 3) continue
        if (!is_a_time(field[3])) { drop("a question whose time is not UTC to the second", line[i]); continue }

        skipped[field[1]] = 1
        first_asked(field[2], field[3])
    }
}

# The earliest time given for a question. A source lists each once, and a second is a source listing
# it twice.
function first_asked(question, when) {
    if (question in asked && asked[question] <= when) return
    asked[question] = when
}

#
# One answer line. `who` runs to the first tab and `when` to the second, and every byte after that is
# the words, tabs and all. A named hand's words are weighed; everyone else's are read past, and a line
# that cannot be read is dropped and said.
#
function hear(   who, when, words) {
    if (NF < 3) { drop("a line that is not who, when and words", $0); return }

    who = $1
    when = $2
    words = after_two_tabs($0)

    if (who == "") { drop("a line that names nobody", $0); return }
    if (!is_a_time(when)) { drop("a line whose time is not UTC to the second", $0); return }

    begin_the_comment(who, when)
    if (who in skipped) return
    if (!(who in hand)) return

    weigh(who, when, plainly(words))
}

function after_two_tabs(line) {
    sub(/^[^\t]*\t[^\t]*\t/, "", line)
    return line
}

# A comment is its lines in a row under one author and one time. The one before it closes first.
function begin_the_comment(who, when) {
    if (who == this_who && when == this_when) return

    close_the_comment()
    this_who = who; this_when = when
    owed = 0; answered = 0; why = ""
}

#
# A yes is the whole line `yes <question>`, or `yes <question> <commit>` at completion, from a named
# hand, to a question `speaker` lists, written strictly after that question was first asked. The first
# reason a line is not one is kept, so a comment that authorised nothing can say why.
#
function weigh(who, when, words,   question) {
    owed = 1
    question = the_question_in(words)
    if (question == "") return

    if (!(question in asked)) { owe("a question nobody asked: " question); return }
    if (!after_its_question(question, when)) { owe("before its question: " question); return }
    if (!shaped_for_its_stage(question)) return

    answered = 1
    printf "%s\t%s\t%s\t%s\t%s\n", (struck ? "struck" : "heard"), question, who, when, words
}

#
# The question a line says yes to, or nothing, with any word after it left in `commit`. The whole line
# is `yes`, one question id, and at most one space and one word of lower-case hex, so a quote reply, a
# no naming the question, and a tab then a no are none of them one. `yes please` is no yes at all.
#
function the_question_in(words,   space) {
    commit = ""
    if (a_strike(words)) return substr(words, 4)
    if (words !~ /^yes [a-z0-9-]+[.][a-z]+[.][0-9]+( [0-9a-f]+)?$/) return ""

    words = substr(words, 5)
    space = index(words, " ")
    if (space == 0) return words

    commit = substr(words, space + 1)
    return substr(words, 1, space - 1)
}

#
# **A no is the whole line `no <question>`**, read as a yes is, and it strikes only a question floor
# named as one a no may strike. Past this it is weighed as a yes: a named hand, after its question.
#
function a_strike(words) {
    struck = words ~ /^no [a-z0-9-]+[.][a-z]+[.][0-9]+$/ && (substr(words, 4) in strikable)
    return struck
}

#
# **Each stage has one shape.** An authorisation names no commit, and a completion names the one its
# hand read, whole. A completion naming none is owed a reason of its own: a person who typed the
# authorisation's shape thinks they answered.
#
function shaped_for_its_stage(question) {
    if (!is_a_completion(question)) return commit == ""
    if (commit == "") { owe("no commit named: " question); return 0 }
    return is_a_whole_commit(commit)
}

function is_a_completion(question) { return question ~ /[.]completion[.][0-9]+$/ }

# 40 or 64 hex digits, as `git rev-parse` prints a commit, so a short sha names none. Counted with
# `length`, since an interval like `{40}` is not in every awk.
function is_a_whole_commit(said) { return length(said) == 40 || length(said) == 64 }

# Strictly after its first ask, with no upper bound. A question asked later closes nothing, so two
# asked back to back are each answerable.
function after_its_question(question, when) {
    return when > asked[question]
}

function owe(said) { if (why == "") why = said }

# A named hand's comment that authorised nothing is owed a row in the ledger, saying why.
function close_the_comment() {
    if (!owed || answered) return
    printf "unread\t%s\t%s\t%s\n", this_who, this_when, reason()
}

function reason() { return why == "" ? "no whole-line yes" : why }

#
# The words are fixed and the space around them is not: spaces and a carriage return at either end,
# one pair of backticks around the whole line, then the first word in any case. None of those can say
# no. A leading `>` stays, so a quote reply is still no yes.
#
function plainly(words) {
    words = trimmed(words)
    words = unquoted(words)
    return first_word_folded(words)
}

function trimmed(said) {
    sub(/^[ \r]+/, "", said)
    sub(/[ \r]+$/, "", said)
    return said
}

# One pair of backticks around the whole line, and only one.
function unquoted(said) {
    if (said !~ /^`.+`$/) return said
    return substr(said, 2, length(said) - 2)
}

function first_word_folded(said,   space) {
    space = index(said, " ")
    if (space == 0) return tolower(said)
    return tolower(substr(said, 1, space - 1)) substr(said, space)
}

# UTC to the second, as a forge writes it. In that one shape, text order is time order.
function is_a_time(said) {
    return said ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z$/
}

# Said, never silent: a line nobody reads looks like a person who never replied.
function drop(what, line) { printf "floor: dropped %s: %s\n", what, line | "cat 1>&2" }
