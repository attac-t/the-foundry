# Puts every GitHub-Flavoured Markdown table on stdin into one canonical shape, and leaves
# everything else byte for byte.
#
# **What this guarantees: the same input gives the same bytes, on every machine.** Run under
# `LC_ALL=C`, always. awk in a UTF-8 locale measures `length` in characters and in C it measures
# bytes, so a padder using `length` answers differently per machine. Width is counted here instead,
# in UTF-8 code points, by ignoring continuation bytes.
#
# **What it does not guarantee: that columns look aligned.** A code point is not a column. Measured
# on three cases, none of which this counts correctly:
#
#     two CJK characters    2 code points, 4 columns   pads 2 too wide
#     one emoji             1 code point,  2 columns   pads 1 too wide
#     e + a combining mark  2 code points, 1 column    pads 1 too narrow
#
# A row holding one of those is off by the difference, and the file is still canonical. That is the
# trade, and it is why the claim above is the narrow one.
#
# What it will not touch: a fenced block, a line with no pipe, and a pipe a backslash escaped. GFM
# says an escape is the only way to put a pipe in a cell, inside a code span as much as outside one.

BEGIN {
    held = 0
    if (budget == "") budget = 120
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

    if (a_table() && measured_width() <= budget) print_table()
    else for (i = 0; i < held; i++) print held_line[i]

    forget()
    held = 0
}

function a_table() { return held >= 2 && is_a_divider(held_line[1]) }

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

# **Padding makes every row as wide as its widest cell.** One long cell drags the whole table out,
# so a block whose canonical form would go over the budget is left exactly as written and
# `bin/table-width.sh` names it. The two never contend for one row.
#
# Fills `rows`, `count`, `columns` and the widest cell per column, then answers how wide the result
# would be. One pass, read twice: once to decide, once to write.
function measured_width(   i, j, n, cell, widest) {
    for (i = 0; i < held; i++) {
        n = cells_of(held_line[i], cell)
        if (n > columns) columns = n

        for (j = 1; j <= n; j++) {
            rows[i, j] = cell[j]
            if (i != 1 && width_of(cell[j]) > wide[j]) wide[j] = width_of(cell[j])
        }
        count[i] = n
    }

    widest = 1
    for (j = 1; j <= columns; j++) {
        if (wide[j] < 3) wide[j] = 3
        widest += wide[j] + 3
    }

    return widest
}

function forget() {
    delete rows; delete wide; delete count
    columns = 0
}

# Writes what `measured_width` already worked out. It leaves the arrays alone; `flush_held` clears
# them, because the branch that does not print here has to clear them too.
function print_table(   i, j, row, out, cellular) {
    for (i = 0; i < held; i++) {
        out = "|"
        for (j = 1; j <= columns; j++) {
            row = ""
            if (j <= count[i]) row = rows[i, j]

            if (i == 1) cellular = dashes(row, wide[j])
            else        cellular = padded(row, wide[j])

            out = out " " cellular " |"
        }
        print out
    }
}

function padded(s, w,   out) {
    out = s
    while (width_of(out) < w) out = out " "
    return out
}

# A divider keeps whichever colons it had, and fills the rest with dashes.
#
# Written out rather than with a ternary inside the concatenation. busybox awk reads
# `(a ? b : c) str` as a call to an undefined function and refuses the whole program.
function dashes(s, w,   left, right, body, out) {
    left  = ""
    right = ""
    if (substr(s, 1, 1) == ":")         left  = ":"
    if (substr(s, length(s), 1) == ":") right = ":"

    body = ""
    while (length(body) + length(left) + length(right) < w) body = body "-"

    out = left body right
    return out
}
