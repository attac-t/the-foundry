# Grades a three-line comment paragraph, and can reflow the ones that fit.
#
# `-v mode=check` names every paragraph that misses. `-v mode=write` prints the
# file back with the fixable ones reflowed and everything else untouched.
#
# Usage: awk -v mode=check -v wide=90 -v step=3 -f taper.awk file.sh
#
# Bytes, under `LC_ALL=C`. An em-dash costs three bytes it never shows, so a
# paragraph holding one is graded on what a formatter can reproduce rather than
# on what a terminal draws. That is the limit, and it is deliberate: a measure
# two locales disagree about cannot gate anything.

BEGIN {
    if (step == "") step = 3
    if (wide == "") wide = 90
    if (mode == "") mode = "check"
}

{ line[FNR] = $0 }

END { mark_heredocs(); walk() }

# Every paragraph in the file, in order, with the code between them kept.
#
# A paragraph is a run of comment lines under one indent. A bare `#`, a change of
# indent and a line of code each end one, so a fenced block is graded paragraph by paragraph.
function walk(   i, j) {
    i = 1
    while (i <= FNR) {
        if (!readable(i)) { emit(i); i++; continue }

        j = i
        while (j <= FNR && readable(j) && indent(line[j]) == indent(line[i])) j++

        judge(i, j - i)
        i = j
    }
}

# Three lines, none of them wide, is the only shape this grades.
#
# Wider than `wide` is prose somebody wrapped at the margin, and nobody hand-shapes
# a line that long. One and two line paragraphs are what `craft-comment` prefers anyway.
function judge(i, n,   a, b, c) {
    if (n != 3 || widest(i, n) >= wide || unsafe(i, n)) { keep(i, n); return }

    a = len(line[i]); b = len(line[i + 1]); c = len(line[i + 2])
    if (a - b == step && b - c == step) { keep(i, n); return }

    if (mode == "write") { reflow(i, a, b, c); return }
    report(i, a, b, c)
}

# One record a caller can read, never a sentence a caller has to parse.
#
# The opener travels with it. A line number moves the moment anything above it is
# edited and the words do not, so an exemption is keyed on the words, not the place.
function report(i, a, b, c) {
    printf "%s\t%d\t%d\t%d\t%d\t%s\t%s\n", \
        FILENAME, i, a, b, c, (fit(i) ? "fits" : "reword"), line[i]
}

function keep(i, n,   k) { for (k = i; k < i + n; k++) emit(k) }

function emit(i) { if (mode == "write") print line[i] }

function widest(i, n,   k, w) {
    for (k = i; k < i + n; k++) if (len(line[k]) > w) w = len(line[k])
    return w
}

# What a reflow would destroy. A list, a table, an indented example, a link and a tool
# directive each carry their own line breaks, so rejoining their words says something else.
function unsafe(i, n,   k, said) {
    for (k = i; k < i + n; k++) {
        said = body(line[k])
        if (said ~ /^[-*|>]/ || said ~ /^   / || said ~ /:\/\// ) return 1
        if (line[k] ~ /^[ \t]*#[ \t]*(shellcheck|shfmt|Usage:)/) return 1
    }
    return 0
}

function len(said) { return length(said) }

# A comment line carrying words. A shebang is not a sentence and a bare `#`
# fences a paragraph rather than opening one, so neither is prose.
function prose(said) {
    return said ~ /^[ \t]*#/ && said !~ /^[ \t]*#[ \t]*$/ && said !~ /^#!/
}

# Is line `i` a comment this may grade? Inside a heredoc, never.
function readable(i) { return prose(line[i]) && !inside[i] }

# A heredoc body is data, whatever it looks like. Reflowing one would rewrite
# what a script prints, so every line to its word is shut.
function mark_heredocs(   i, word, k) {
    for (i = 1; i <= FNR; i++) {
        word = opener_word(line[i])
        if (word == "") continue

        for (k = i + 1; k <= FNR; k++) {
            inside[k] = 1
            if (ends_heredoc(line[k], word)) break
        }
        i = k
    }
}

# The word a heredoc ends on, or nothing. `<<-` and either quote are the three
# spellings, and a here-string `<<<` is not a heredoc at all.
function opener_word(said,   t) {
    if (said ~ /<<</) return ""
    if (said !~ /<<-?[ \t]*["']?[A-Za-z_][A-Za-z0-9_]*/) return ""

    t = said
    sub(/^.*<<-?[ \t]*/, "", t)
    sub(/^["']/, "", t)
    sub(/[^A-Za-z0-9_].*$/, "", t)
    return t
}

function ends_heredoc(said, word,   t) {
    t = said
    sub(/^[ \t]*/, "", t)
    return t == word
}

function indent(said,   t) { t = said; sub(/#.*$/, "", t); return t }

function body(said,   t) { t = said; sub(/^[ \t]*#[ \t]?/, "", t); return t }

# The words of a paragraph, in one string, spaced once.
function words_of(i,   t) {
    t = body(line[i]) " " body(line[i + 1]) " " body(line[i + 2])
    gsub(/[ \t]+/, " ", t)
    return t
}

# Is there a split into three lines that steps down twice by `step`?
#
# The three lengths sum to a fixed total, so a split exists only when that total divides
# by three — and even then the word boundaries have to land on it. Most never do.
function fit(i,   m, w, p, q) {
    m = split(words_of(i), w, " ")
    for (p = 1; p < m - 1; p++)
        for (q = p + 1; q < m; q++)
            if (steps(w, m, p, q, len(indent(line[i])) + 2)) return 1
    return 0
}

function steps(w, m, p, q, pre,   a, b, c) {
    a = run(w, 1, p, pre); b = run(w, p + 1, q, pre); c = run(w, q + 1, m, pre)
    return a - b == step && b - c == step && a < wide
}

function run(w, from, to, pre,   k, n) {
    n = pre - 1
    for (k = from; k <= to; k++) n += length(w[k]) + 1
    return n
}

# Print the paragraph reflowed, or unchanged when nothing fits.
function reflow(i, a, b, c,   m, w, p, q, pre) {
    pre = len(indent(line[i])) + 2
    m = split(words_of(i), w, " ")

    for (p = 1; p < m - 1; p++)
        for (q = p + 1; q < m; q++)
            if (steps(w, m, p, q, pre)) { say(w, i, 1, p); say(w, i, p + 1, q); say(w, i, q + 1, m); return }

    keep(i, 3)
}

function say(w, i, from, to,   k, said) {
    said = indent(line[i]) "#"
    for (k = from; k <= to; k++) said = said " " w[k]
    print said
}
