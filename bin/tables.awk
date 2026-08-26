# Formats every GitHub-Flavoured Markdown table on stdin, and leaves everything else byte for byte.
#
# Run under `LC_ALL=C`, always. That is not a preference: awk in a UTF-8 locale
# measures `length` in characters and in C it measures bytes, so the same
# table comes out ragged on the next machine.
#
# So width is counted here instead, in UTF-8 code points, by ignoring
# continuation bytes. One rule, every locale, same bytes out.
#
# What it will not touch: a fenced block, a line with no pipe, and a pipe a
# backslash escaped. GFM says an escape is the only way to put a pipe in a
# cell, inside a code span as much as outside one, so that is the only case.

BEGIN {
    held = 0
    for (b = 128; b <= 191; b++) continuation[sprintf("%c", b)] = 1
}

/^[ \t]*(```|~~~)/ { fenced = !fenced }

fenced { flush_held(); print; next }

# A table is a run of pipe lines whose second line divides it. Anything else
# holding a pipe is prose, and prose is none of this file's business.
/\|/  { held_line[held++] = $0; next }
       { flush_held(); print; next }

END { flush_held() }

function flush_held(   i) {
    if (held == 0) return

    if (held >= 2 && is_a_divider(held_line[1])) print_table()
    else for (i = 0; i < held; i++) print held_line[i]

    held = 0
}

# The second row decides. Every cell in it is dashes, with a colon allowed at
# either end for alignment.
function is_a_divider(line,   n, cell, i) {
    n = cells_of(line, cell)
    if (n == 0) return 0

    for (i = 1; i <= n; i++)
        if (cell[i] !~ /^:?-+:?$/) return 0

    return 1
}

# Splits a row into cells. A leading and trailing pipe are the fence, not a
# cell, so both go. A `\|` is content and stays whole.
function cells_of(line, out,   n, i, c, buf) {
    sub(/^[ \t]+/, "", line)
    sub(/[ \t]+$/, "", line)
    sub(/^\|/, "", line)
    sub(/\|$/, "", line)

    n = 0; buf = ""
    for (i = 1; i <= length(line); i++) {
        c = substr(line, i, 1)

        if (c == "\\" && substr(line, i + 1, 1) == "|") { buf = buf "\\|"; i++; continue }
        if (c == "|") { out[++n] = trimmed(buf); buf = ""; continue }

        buf = buf c
    }

    out[++n] = trimmed(buf)
    return n
}

function trimmed(s) {
    sub(/^[ \t]+/, "", s)
    sub(/[ \t]+$/, "", s)
    return s
}

# Code points, never bytes. A UTF-8 continuation byte is 0x80 to 0xBF and
# belongs to the character before it, so it is not counted.
function width_of(s,   i, n) {
    n = 0
    for (i = 1; i <= length(s); i++)
        if (!(substr(s, i, 1) in continuation)) n++

    return n
}

function print_table(   i, j, n, cell, wide, rows, row, out, pad) {
    for (i = 0; i < held; i++) {
        n = cells_of(held_line[i], cell)
        if (n > columns) columns = n

        for (j = 1; j <= n; j++) {
            rows[i, j] = cell[j]
            if (i != 1 && width_of(cell[j]) > wide[j]) wide[j] = width_of(cell[j])
        }
        count[i] = n
    }

    for (j = 1; j <= columns; j++) if (wide[j] < 3) wide[j] = 3

    for (i = 0; i < held; i++) {
        out = "|"
        for (j = 1; j <= columns; j++) {
            row = (j <= count[i]) ? rows[i, j] : ""
            out = out " " (i == 1 ? dashes(row, wide[j]) : padded(row, wide[j])) " |"
        }
        print out
    }

    delete rows; delete wide; delete count
    columns = 0
}

function padded(s, w,   out) {
    out = s
    while (width_of(out) < w) out = out " "
    return out
}

# A divider keeps whichever colons it had, and fills the rest with dashes.
function dashes(s, w,   left, right, body) {
    left  = (substr(s, 1, 1) == ":")
    right = (substr(s, length(s), 1) == ":")

    body = ""
    while (length(body) < w - left - right) body = body "-"

    return (left ? ":" : "") body (right ? ":" : "")
}
