# Reports a three-line comment block whose steps do not narrow evenly.
#
# Its own file, because embedded in a single-quoted string it was six jobs with
# no names — the shape `craft-sh` refuses in shell, and
# a string is not a reason to stop refusing it.
#
# Usage: awk -v wide=90 -f taper.awk file.sh

{ line[FNR] = $0 }

END { for (i = 1; i <= FNR; i++) if (block_at(i)) grade(i) }

# Three of them, nothing above, code below.
function block_at(i) {
    return opens(i) && prose(line[i + 1]) && prose(line[i + 2]) && above_code(i)
}

function opens(i) { return prose(line[i]) && !prose(line[i - 1]) }

# A shebang is not a sentence, and a bare `#` fences a paragraph rather than
# starting one. Both read as comment lines and
# neither begins a taper.
function prose(said) {
    return said ~ /^#/ && said !~ /^#[[:space:]]*$/ && said !~ /^#!/
}

# The line under the block. Blank means the comment floats, and another `#`
# means the block is longer than three.
function above_code(i) {
    return line[i + 3] ~ /[^[:space:]]/ && line[i + 3] !~ /^#/
}

# Prose wrapped at the margin lands near a hundred and is not a taper. Nobody
# hand-shapes a line to that width, so a wide first
# line is read as a paragraph and left alone.
function grade(i,   a, b, c) {
    a = length(line[i]); b = length(line[i + 1]); c = length(line[i + 2])

    if (a >= wide || narrows_evenly(a, b, c)) return
    printf "    %s:%d  %d %d %d\n", FILENAME, i, a, b, c
}

function narrows_evenly(a, b, c) {
    return a > b && b > c && even(a - b, b - c)
}

# Within three. `craft-comment` measured why: a fixed step is met by padding in
# fifty-seven cases out of fifty-nine, and padding is
# the waste the whole rule exists to refuse.
function even(one, two) { return one - two <= 3 && two - one <= 3 }
