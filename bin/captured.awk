# Every name a shipped line captures, one a line. Read by `bin/shell.sh` for its captured-answer rule.
#
# A capture runs from `$(` until its brackets balance, on its own line or on the lines after it. Each
# name in command position inside it is read: after `$(`, after a pipe or a list operator, and at the
# head of each line the capture spans. #1202: a `$(` at a line's end, and `$(a | b)`, named only what
# followed `$(` on its own line.
#
# **Never less than that.** Every `$(` on every line is read whatever the depth, so a bracket counted
# wrong can only stop a capture reading on, never lose a name the one-line reading found.

FNR == 1 { depth = 0 }

/^[ \t]*#/ { next }

{
    was_open = depth
    if (was_open) name_the_head($0)
    name_every_capture($0)
    depth += brackets_counted_from(was_open, $0)
    if (depth < 0) depth = 0
}

# Each bracket once: the whole line inside a capture, or from the line's first `$(` when it opens one.
function brackets_counted_from(was_open, line) {
    if (was_open) return balance_of(line)
    if (!match(line, /\$\(/)) return 0
    return balance_of(substr(line, RSTART))
}

# The first name on a line inside a capture, past any leading pipe or list operator.
function name_the_head(line) {
    sub(/^[ \t]*(\|\||&&|\||;)?[ \t]*/, "", line)
    name_at_start(line)
}

function name_every_capture(rest) {
    while (match(rest, /\$\(/)) {
        rest = substr(rest, RSTART + 2)
        name_each_command(rest)
    }
}

# A name at the start, and after every pipe, `||`, `&&` or `;` that follows it on the line.
function name_each_command(text) {
    name_at_start(text)
    while (match(text, /(\|\||&&|\||;)[ \t]*/)) {
        text = substr(text, RSTART + RLENGTH)
        name_at_start(text)
    }
}

function name_at_start(text) {
    if (match(text, /^[A-Za-z_][A-Za-z0-9_]*/)) print substr(text, 1, RLENGTH)
}

# Opens less closes. A quoted bracket, a `case` arm or a heredoc's `)` miscounts.
function balance_of(text,    opens) {
    opens = gsub(/\(/, "(", text)
    return opens - gsub(/\)/, ")", text)
}
